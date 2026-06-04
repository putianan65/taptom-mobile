import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/plot_service.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../data/models/plot_model.dart';
import '../../map/screens/plot_detail_screen.dart';

class MyPlotsMapScreen extends StatefulWidget {
  const MyPlotsMapScreen({super.key});

  @override
  State<MyPlotsMapScreen> createState() => _MyPlotsMapScreenState();
}

class _MyPlotsMapScreenState extends State<MyPlotsMapScreen> {
  MaplibreMapController? _mapController;
  final String _styleUrl =
      'https://api.maptiler.com/maps/hybrid/style.json?key=Fb4cbU6chnBsGVsZ5v96';

  List<PlotModel> _plots = [];
  bool _isLoading = true;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadPlots();
  }

  Future<void> _checkLocationPermission() async {
    final granted = await PermissionUtils.requestLocationPermission(context);
    if (mounted) {
      setState(() => _locationEnabled = granted);
    }
  }

  Future<void> _loadPlots() async {
    try {
      final plots = await context.read<PlotService>().getMyPlots();
      setState(() {
        _plots = plots;
        _isLoading = false;
      });
      _updateMap();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load plots: $e')));
      }
    }
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
    _mapController!.onFillTapped.add(_onFillTapped);
  }

  void _onStyleLoaded() {
    _updateMap();
  }

  void _updateMap() async {
    if (_mapController == null || _plots.isEmpty) return;

    // Clear existing fills if any (naive approach, usually we track IDs)
    await _mapController!.clearFills();

    // Calculate bounds to fit all plots
    double? minLat, maxLat, minLng, maxLng;

    for (var plot in _plots) {
      if (plot.boundary.isEmpty) continue;

      // Determine color based on status
      String color = AppColors.primary.toHexStringRGB();
      if (plot.status == 'PENDING') color = '#FFA500'; // Orange
      if (plot.status == 'REJECTED') color = '#FF0000'; // Red

      // Add Fill
      await _mapController!.addFill(
        FillOptions(
          geometry: [plot.boundary],
          fillColor: color,
          fillOpacity: 0.5,
          fillOutlineColor: '#FFFFFF',
        ),
        {'plotId': plot.id}, // Metadata for tap handling
      );

      // Expand bounds
      for (var point in plot.boundary) {
        if (minLat == null || point.latitude < minLat) minLat = point.latitude;
        if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
        if (minLng == null || point.longitude < minLng)
          minLng = point.longitude;
        if (maxLng == null || point.longitude > maxLng)
          maxLng = point.longitude;
      }
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          left: 50,
          right: 50,
          top: 50,
          bottom: 50,
        ),
      );
    }
  }

  void _onFillTapped(Fill fill) {
    final plotId = fill.data?['plotId'];
    if (plotId != null) {
      final plot = _plots.firstWhere(
        (p) => p.id == plotId,
        orElse: () => _plots.first,
      );
      _showPlotInfo(plot);
    }
  }

  void _showPlotInfo(PlotModel plot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plot.name,
              style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${plot.species ?? 'Unknown'} • ${plot.areaRai ?? 0} Rai',
              style: GoogleFonts.prompt(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close sheet
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlotDetailScreen(plot: plot),
                    ),
                  );
                  // Refresh plot list if returned with true (after delete)
                  if (result == true) {
                    if (!mounted) return;
                    _loadPlots();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('ดูรายละเอียด', style: GoogleFonts.prompt()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'ภาพรวมแปลงเกษตร',
          style: GoogleFonts.prompt(color: Colors.black),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MaplibreMap(
            styleString: _styleUrl,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.7, 100.5),
              zoom: 5,
            ),
            myLocationEnabled: _locationEnabled,
            myLocationRenderMode: MyLocationRenderMode.normal,
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
