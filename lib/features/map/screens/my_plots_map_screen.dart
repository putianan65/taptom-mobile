import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/env.dart';
import '../../../core/services/plot_service.dart';
import '../../../core/utils/map_styles.dart';
import '../../../core/utils/permission_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../widgets/map_controls.dart';
import '../widgets/plot_card.dart';
import 'map_drawing_screen.dart';
import 'plot_detail_screen.dart';

/// All of a farmer's plots on satellite imagery. A card carousel at the
/// bottom stays in sync with the map: swiping a card flies to that plot and
/// tapping a polygon brings its card into view.
class MyPlotsMapScreen extends StatefulWidget {
  const MyPlotsMapScreen({super.key, this.embedded = false});

  /// True when shown as a dashboard tab (no back button, room for the nav
  /// bar).
  final bool embedded;

  @override
  State<MyPlotsMapScreen> createState() => _MyPlotsMapScreenState();
}

class _MyPlotsMapScreenState extends State<MyPlotsMapScreen> {
  final _cards = PageController(viewportFraction: 0.86);
  MapLibreMapController? _map;
  List<PlotModel> _plots = [];
  bool _loading = true;
  bool _styleReady = false;
  bool _locationEnabled = false;
  String? _error;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
    if (!kIsWeb && !Env.demoMode) _requestLocation();
  }

  @override
  void dispose() {
    _cards.dispose();
    _map?.onFillTapped.remove(_onFillTapped);
    super.dispose();
  }

  Future<void> _requestLocation() async {
    final granted = await PermissionUtils.requestLocationPermission(context);
    if (mounted) setState(() => _locationEnabled = granted);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plots = await context.read<PlotService>().getMyPlots();
      if (!mounted) return;
      setState(() {
        _plots = plots.where((p) => p.boundary.length >= 3).toList();
        _loading = false;
        _selected = 0;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
      return;
    }
    await _drawPlots();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _map = controller;
    controller.onFillTapped.add(_onFillTapped);
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    await _drawPlots();
  }

  Future<void> _drawPlots() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    try {
      await _paint(map);
    } catch (e) {
      // A rendering failure leaves the cards usable; it must not read as a
      // failed fetch.
      debugPrint('Plot overlay failed: $e');
    }
  }

  Future<void> _paint(MapLibreMapController map) async {
    await map.clearFills();
    await map.clearLines();
    for (final plot in _plots) {
      final color = MapStyles.fillFor(plot.status);
      await map.addFill(
        FillOptions(
          geometry: [[...plot.boundary, plot.boundary.first]],
          fillColor: color,
          fillOutlineColor: color,
          fillOpacity: 0.42,
        ),
        {'plotId': plot.id},
      );
      await map.addLine(
        LineOptions(
          geometry: [...plot.boundary, plot.boundary.first],
          lineColor: MapStyles.plotLine,
          lineWidth: 2,
        ),
      );
    }
    await _fitAll();
  }

  LatLngBounds? _bounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _fitAll() async {
    final bounds = _bounds([for (final p in _plots) ...p.boundary]);
    if (bounds == null) return;
    await _map?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 60, right: 60, top: 140, bottom: 260),
    );
  }

  Future<void> _focus(int index) async {
    if (index < 0 || index >= _plots.length) return;
    final bounds = _bounds(_plots[index].boundary);
    if (bounds == null) return;
    await _map?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 80, right: 80, top: 160, bottom: 280),
    );
  }

  void _onFillTapped(Fill fill) {
    final id = fill.data?['plotId'];
    final index = _plots.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _cards.animateToPage(index, duration: Motion.slow, curve: Motion.emphasized);
  }

  Future<void> _open(PlotModel plot) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlotDetailScreen(plot: plot)),
    );
    if (changed == true) _load();
  }

  Future<void> _draw() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapDrawingScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    final navSpace = widget.embedded && context.isCompact ? 76.0 : 0.0;
    final bottom = MediaQuery.paddingOf(context).bottom + navSpace;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          MapLibreMap(
            styleString: MapStyles.satellite,
            initialCameraPosition: MapStyles.thailand,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            myLocationEnabled: _locationEnabled,
            compassEnabled: false,
            trackCameraPosition: false,
          ),
          Positioned(
            top: top + Space.md,
            left: Space.lg,
            right: Space.lg,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MapTopBar(
                      title: 'แปลงของฉัน',
                      subtitle: _loading
                          ? 'กำลังโหลด'
                          : '${_plots.length} แปลงบนแผนที่',
                      onBack: widget.embedded ? null : () => Navigator.of(context).maybePop(),
                      trailing: IconButton(
                        tooltip: 'โหลดใหม่',
                        onPressed: _load,
                        icon: const Icon(AppIcons.refresh),
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    const MapLegend(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: Space.lg,
            bottom: bottom + (_plots.isEmpty ? 96 : 196),
            child: Column(
              children: [
                MapFab(icon: AppIcons.gridFour, tooltip: 'ดูทุกแปลง', onPressed: _fitAll),
                const SizedBox(height: Space.sm),
                MapFab(icon: AppIcons.add, tooltip: 'วาดแปลงใหม่', onPressed: _draw, active: true),
              ],
            ),
          ),
          if (_loading)
            Positioned(
              top: top + 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: Radii.chip,
                    boxShadow: [BoxShadow(color: p.shadow, blurRadius: 12)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: p.brand),
                      ),
                      const SizedBox(width: Space.sm),
                      Text('กำลังโหลดแปลง', style: context.text.labelLarge),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom + Space.lg,
            child: _bottomPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_error != null || _plots.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: AppCard(
              child: Row(
                children: [
                  const FarmerMascot(size: 64, mood: MascotMood.think, animated: false),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _error != null ? 'โหลดแปลงไม่สำเร็จ' : 'ยังไม่มีแปลงบนแผนที่',
                          style: context.text.titleSmall,
                        ),
                        Text(
                          _error != null
                              ? 'แตะเพื่อลองใหม่'
                              : 'แตะปุ่ม + เพื่อวาดขอบเขตแปลงแรก',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    IconButton(onPressed: _load, icon: const Icon(AppIcons.refresh)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 112,
      child: PageView.builder(
        controller: _cards,
        itemCount: _plots.length,
        onPageChanged: (i) {
          setState(() => _selected = i);
          _focus(i);
        },
        itemBuilder: (context, i) => AnimatedScale(
          duration: Motion.base,
          scale: i == _selected ? 1 : 0.94,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: PlotCard(plot: _plots[i], onTap: () => _open(_plots[i])),
          ),
        ),
      ),
    );
  }
}
