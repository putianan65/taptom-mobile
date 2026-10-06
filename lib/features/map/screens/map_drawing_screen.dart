import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/services/plot_service.dart';
import '../../../core/utils/geo_json_utils.dart';
import '../../../core/utils/map_styles.dart';
import '../../../core/utils/permission_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../widgets/map_controls.dart';

/// Draws or edits a plot boundary by tapping corners on satellite imagery.
///
/// One screen serves four jobs: a member registering a plot, a member
/// correcting their own boundary, an officer registering a plot for a
/// member ([targetUserId]) and an officer correcting any boundary in their
/// territory ([isAdmin] with [plotToEdit]). Pops with the saved [PlotModel]
/// (or `true` when the API returns no body).
class MapDrawingScreen extends StatefulWidget {
  const MapDrawingScreen({super.key, this.plotToEdit, this.isAdmin = false, this.targetUserId});

  final PlotModel? plotToEdit;
  final bool isAdmin;
  final String? targetUserId;

  @override
  State<MapDrawingScreen> createState() => _MapDrawingScreenState();
}

class _MapDrawingScreenState extends State<MapDrawingScreen> {
  static const _vertexColor = '#FFFFFF';
  static const _edgeColor = '#F5DE9E';

  MapLibreMapController? _map;
  bool _styleReady = false;
  bool _locationEnabled = false;
  bool _saving = false;

  final List<LatLng> _points = [];
  final List<Circle> _vertices = [];
  Line? _edge;
  Fill? _fill;

  bool get _editing => widget.plotToEdit != null;
  bool get _dirty => _editing ? !listEquals(_points, widget.plotToEdit!.boundary) : _points.isNotEmpty;
  ThaiArea get _area => ThaiArea.fromSqm(GeoJsonUtils.areaSqm(_points));

  @override
  void initState() {
    super.initState();
    if (_editing) _points.addAll(widget.plotToEdit!.boundary);
  }

  @override
  void dispose() {
    _map?.onFeatureDrag.remove(_onDrag);
    super.dispose();
  }

  // Map ----------------------------------------------------------------------

  void _onMapCreated(MapLibreMapController controller) {
    _map = controller;
    controller.onFeatureDrag.add(_onDrag);
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    await _redraw();
    if (_points.length >= 3) await _fit();
  }

  Future<void> _fit() async {
    if (_points.isEmpty) return;
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in _points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    await _map?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        left: 60,
        right: 60,
        top: 180,
        bottom: 260,
      ),
    );
  }

  Future<void> _locate() async {
    if (!_locationEnabled) {
      final granted = await PermissionUtils.requestLocationPermission(context);
      if (!mounted || !granted) return;
      setState(() => _locationEnabled = true);
    }
    final here = await _map?.requestMyLocationLatLng();
    if (here != null) await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 17));
  }

  Future<void> _redraw() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    try {
      if (_fill != null) await map.removeFill(_fill!);
      if (_edge != null) await map.removeLine(_edge!);
      if (_vertices.isNotEmpty) await map.removeCircles(_vertices);
      _fill = null;
      _edge = null;
      _vertices.clear();

      if (_points.length >= 3) {
        _fill = await map.addFill(
          FillOptions(
            geometry: [
              [..._points, _points.first],
            ],
            fillColor: MapStyles.plotFill,
            fillOutlineColor: MapStyles.plotFill,
            fillOpacity: 0.4,
          ),
        );
      }
      if (_points.length >= 2) {
        _edge = await map.addLine(
          LineOptions(
            geometry: _points.length >= 3 ? [..._points, _points.first] : _points,
            lineColor: _edgeColor,
            lineWidth: 2.5,
          ),
        );
      }
      for (final (i, p) in _points.indexed) {
        _vertices.add(
          await map.addCircle(
            CircleOptions(
              geometry: p,
              circleRadius: i == 0 ? 8 : 6.5,
              circleColor: i == 0 ? MapStyles.plotFill : _vertexColor,
              circleStrokeColor: i == 0 ? _vertexColor : MapStyles.plotFill,
              circleStrokeWidth: 2.5,
              draggable: !kIsWeb,
            ),
            {'index': i},
          ),
        );
      }
    } on Object catch (e) {
      debugPrint('Boundary redraw failed: $e');
    }
  }

  void _onDrag(
    math.Point<double> point,
    LatLng origin,
    LatLng current,
    LatLng delta,
    String id,
    Annotation? annotation,
    DragEventType type,
  ) {
    if (type != DragEventType.end || annotation is! Circle) return;
    final index = annotation.data?['index'];
    if (index is! int || index >= _points.length) return;
    HapticFeedback.selectionClick();
    setState(() => _points[index] = current);
    _redraw();
  }

  // Editing ------------------------------------------------------------------

  void _onTap(math.Point<double> _, LatLng latLng) {
    if (_saving) return;
    HapticFeedback.selectionClick();
    setState(() => _points.add(latLng));
    _redraw();
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(_points.removeLast);
    _redraw();
  }

  Future<void> _clear() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ล้างจุดทั้งหมด?',
      message: 'เริ่มวาดขอบเขตใหม่ตั้งแต่จุดแรก',
      confirmLabel: 'ล้าง',
      destructive: true,
    );
    if (!ok) return;
    setState(_points.clear);
    _redraw();
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty || _saving) return true;
    return AppDialogs.confirm(
      context,
      title: 'ออกโดยไม่บันทึก?',
      message: 'ขอบเขตที่วาดไว้จะหายไป',
      confirmLabel: 'ออก',
      cancelLabel: 'วาดต่อ',
      destructive: true,
    );
  }

  // Saving -------------------------------------------------------------------

  Future<void> _save() async {
    if (_points.length < 3) return;
    if (GeoJsonUtils.selfIntersects(_points)) {
      AppToast.error(context, 'เส้นขอบแปลงตัดกัน ลากจุดหรือย้อนจุดล่าสุดให้เส้นไม่ไขว้กัน');
      return;
    }
    String? name = widget.plotToEdit?.name;
    if (!_editing) {
      name = await showAppSheet<String>(
        context,
        title: 'ตั้งชื่อแปลง',
        subtitle: 'พื้นที่ประมาณ $_area',
        child: _NameForm(area: _area),
      );
      if (name == null || name.isEmpty || !mounted) return;
    }

    setState(() => _saving = true);
    final geometry = GeoJsonUtils.toPolygon(_points);
    final plots = context.read<PlotService>();
    final admin = context.read<AdminService>();
    try {
      Object result = true;
      if (_editing && widget.isAdmin) {
        await admin.adminUpdatePlot(widget.plotToEdit!.id!, geometry);
        result = widget.plotToEdit!.copyWith(geometry: geometry);
      } else if (_editing) {
        result = await plots.updatePlotGeometry(plotId: widget.plotToEdit!.id!, geometry: geometry);
      } else if (widget.targetUserId != null) {
        await admin.createPlotForUser(
          userId: widget.targetUserId!,
          plot: PlotModel(name: name!, geometry: geometry, areaRai: _area.inRai),
        );
      } else {
        result = await plots.createPlot(PlotModel(name: name!, geometry: geometry, areaRai: _area.inRai));
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (_editing) {
        AppToast.success(context, 'บันทึกขอบเขตใหม่แล้ว');
      } else {
        await AppDialogs.message(
          context,
          title: 'บันทึกแปลงแล้ว',
          message: widget.targetUserId != null
              ? '$name ($_area) ถูกเพิ่มให้สมาชิกแล้ว'
              : '$name ($_area) ส่งให้เจ้าหน้าที่ตรวจแล้ว ระหว่างนี้เริ่มบันทึกข้อมูล GAP ได้เลย',
          tone: Tone.success,
          mood: MascotMood.joy,
        );
      }
      if (mounted) Navigator.of(context).pop(result);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final title = switch ((_editing, widget.targetUserId != null)) {
      (true, _) => 'แก้ไขขอบเขต',
      (false, true) => 'วาดแปลงให้สมาชิก',
      _ => 'วาดแปลงใหม่',
    };
    final hint = _points.isEmpty
        ? 'แตะที่มุมแปลงทีละจุดบนภาพถ่ายดาวเทียม'
        : GeoJsonUtils.selfIntersects(_points)
        ? 'เส้นขอบตัดกัน ปรับจุดให้เส้นไม่ไขว้กัน'
        : _points.length < 3
        ? 'แตะเพิ่มอีก ${3 - _points.length} จุดเพื่อปิดรูปแปลง'
        : kIsWeb
        ? 'แตะเพิ่มจุดได้อีก หรือบันทึกเมื่อครบทุกมุม'
        : 'ลากจุดเพื่อปรับตำแหน่ง หรือบันทึกเมื่อครบทุกมุม';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            MapLibreMap(
              styleString: MapStyles.satellite,
              initialCameraPosition: _points.isNotEmpty
                  ? CameraPosition(target: _points.first, zoom: 16)
                  : const CameraPosition(target: LatLng(16.84, 100.43), zoom: 13),
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              onMapClick: _onTap,
              myLocationEnabled: _locationEnabled,
              compassEnabled: false,
              tiltGesturesEnabled: false,
              trackCameraPosition: false,
            ),
            Positioned(
              top: top + Space.md,
              left: Space.lg,
              right: Space.lg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: MapTopBar(
                    title: title,
                    subtitle: hint,
                    onBack: () async {
                      if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: Space.lg,
              bottom: bottom + 196,
              child: Column(
                children: [
                  if (!kIsWeb) ...[
                    MapFab(icon: AppIcons.locate, tooltip: 'ตำแหน่งของฉัน', onPressed: _locate),
                    const SizedBox(height: Space.sm),
                  ],
                  MapFab(icon: AppIcons.gridFour, tooltip: 'ดูทั้งแปลง', onPressed: _points.length >= 2 ? _fit : null),
                ],
              ),
            ),
            Positioned(
              left: Space.lg,
              right: Space.lg,
              bottom: bottom + Space.lg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _Panel(
                    area: _area,
                    points: _points.length,
                    saving: _saving,
                    saveLabel: _editing ? 'บันทึกขอบเขต' : 'ถัดไป',
                    onUndo: _points.isEmpty ? null : _undo,
                    onClear: _points.length < 2 ? null : _clear,
                    onSave: _points.length >= 3 && _dirty ? _save : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.area,
    required this.points,
    required this.saving,
    required this.saveLabel,
    this.onUndo,
    this.onClear,
    this.onSave,
  });

  final ThaiArea area;
  final int points;
  final bool saving;
  final String saveLabel;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget unit(int value, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedSwitcher(
          duration: Motion.quick,
          transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
          child: Text(
            '$value',
            key: ValueKey(value),
            style: context.text.headlineMedium?.tabular.copyWith(color: p.ink),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: context.text.labelMedium),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.card,
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Space.md,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [unit(area.rai, 'ไร่'), unit(area.ngan, 'งาน'), unit(area.wah, 'ตร.ว.')],
                ),
              ),
              Text('$points จุด', style: context.text.labelMedium?.tabular),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              AppIconButton(icon: AppIcons.undo, tooltip: 'ย้อนจุดล่าสุด', onPressed: saving ? null : onUndo),
              const SizedBox(width: Space.sm),
              AppIconButton(icon: AppIcons.delete, tooltip: 'ล้างทั้งหมด', onPressed: saving ? null : onClear),
              const SizedBox(width: Space.md),
              Expanded(
                child: AppButton(label: saveLabel, icon: AppIcons.check, loading: saving, onPressed: onSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NameForm extends StatefulWidget {
  const _NameForm({required this.area});

  final ThaiArea area;

  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'ชื่อแปลง',
            controller: _name,
            hint: 'เช่น สวนกระท่อมหลังบ้าน',
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Space.lg),
          AppButton(label: 'บันทึกแปลง', expand: true, onPressed: _name.text.trim().isEmpty ? null : _submit),
        ],
      ),
    );
  }
}
