import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/utils/map_styles.dart';
import '../../../core/utils/permission_utils.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../map/widgets/map_controls.dart';
import 'admin_gap_inspection_screen.dart';
import 'create_plot_for_user_screen.dart';
import '../../map/screens/map_drawing_screen.dart';

/// Staff map of every plot in scope. Admins see their territory, super
/// admins see the country. Plots are drawn as polygons with a status dot at
/// the centroid so they stay findable when zoomed out to province level.
class AdminPlotsMapScreen extends StatefulWidget {
  const AdminPlotsMapScreen({super.key, this.userId, this.isMainTab = false});

  /// Limits the map to one member's plots.
  final String? userId;

  /// True when shown as a tab in the staff shell (no back button, leaves
  /// room for the bottom bar).
  final bool isMainTab;

  @override
  State<AdminPlotsMapScreen> createState() => _AdminPlotsMapScreenState();
}

class _AdminPlotsMapScreenState extends State<AdminPlotsMapScreen> {
  MapLibreMapController? _map;
  bool _styleReady = false;
  bool _locationEnabled = false;

  List<Map<String, dynamic>> _plots = [];
  bool _loading = true;
  String? _error;
  String? _status;

  List<Map<String, dynamic>> get _visible => _status == null
      ? _plots
      : _plots.where((p) => p['status'] == _status).toList();

  int _count(String status) => _plots.where((p) => p['status'] == status).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _map?.onFillTapped.remove(_onFillTapped);
    _map?.onCircleTapped.remove(_onCircleTapped);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final service = context.read<AdminService>();
    try {
      final plots = await service.getAdminPlots(userId: widget.userId);
      final list = [
        for (final p in plots)
          if (p is Map) Map<String, dynamic>.from(p),
      ];

      // Some list responses omit the owner; join it from the member list.
      if (list.any((p) => _owner(p) == null)) {
        try {
          final users = await service.getUsers();
          final byId = {for (final u in users) u.id: u.toJson()};
          for (final p in list) {
            final id = p['userId'] ?? p['ownerId'];
            if (_owner(p) == null && byId.containsKey(id)) p['owner'] = byId[id];
          }
        } on Object catch (e) {
          debugPrint('Owner join skipped: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _plots = list;
        _loading = false;
      });
      await _draw(fit: true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // Map --------------------------------------------------------------------

  void _onMapCreated(MapLibreMapController controller) {
    _map = controller;
    controller.onFillTapped.add(_onFillTapped);
    controller.onCircleTapped.add(_onCircleTapped);
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    await _draw(fit: true);
  }

  Future<void> _draw({bool fit = false}) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    try {
      await map.clearFills();
      await map.clearLines();
      await map.clearCircles();
      for (final plot in _visible) {
        final ring = _ring(plot);
        if (ring.length < 3) continue;
        final color = MapStyles.fillFor(plot['status'] as String?);
        final data = {'plotId': plot['id']};
        await map.addFill(
          FillOptions(geometry: [ring], fillColor: color, fillOutlineColor: color, fillOpacity: 0.38),
          data,
        );
        await map.addLine(
          LineOptions(
            geometry: [...ring, ring.first],
            lineColor: MapStyles.plotLine,
            lineWidth: 1.5,
          ),
        );
        await map.addCircle(
          CircleOptions(
            geometry: _centroid(ring),
            circleRadius: 6,
            circleColor: color,
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
          data,
        );
      }
      if (fit) await _fitAll();
    } on Object catch (e) {
      debugPrint('Plot overlay failed: $e');
    }
  }

  Future<void> _fitAll() async {
    final points = [for (final p in _visible) ..._ring(p)];
    if (points.isEmpty) return;
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    await _map?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        left: 48,
        right: 48,
        top: 200,
        bottom: 160,
      ),
    );
  }

  Future<void> _focus(Map<String, dynamic> plot) async {
    final ring = _ring(plot);
    if (ring.isEmpty) return;
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(_centroid(ring), 15.5));
  }

  Future<void> _locate() async {
    if (!_locationEnabled) {
      final granted = await PermissionUtils.requestLocationPermission(context);
      if (!mounted || !granted) return;
      setState(() => _locationEnabled = true);
    }
    final here = await _map?.requestMyLocationLatLng();
    if (here != null) await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 14));
  }

  void _onFillTapped(Fill fill) => _openById(fill.data?['plotId']);

  void _onCircleTapped(Circle circle) => _openById(circle.data?['plotId']);

  void _openById(Object? id) {
    final plot = _plots.where((p) => p['id'] == id).firstOrNull;
    if (plot != null) _openPlot(plot);
  }

  // Navigation -------------------------------------------------------------

  Future<void> _openPlot(Map<String, dynamic> plot) async {
    await showAppSheet<void>(
      context,
      child: _PlotSheet(initial: plot, onChanged: _load),
    );
  }

  Future<void> _openList() async {
    final picked = await showAppSheet<Map<String, dynamic>>(
      context,
      title: 'รายการแปลง',
      subtitle: '${_visible.length} แปลง',
      expand: true,
      child: _PlotList(plots: _visible),
    );
    if (picked == null || !mounted) return;
    await _focus(picked);
    if (mounted) await _openPlot(picked);
  }

  Future<void> _createPlot() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePlotForUserScreen()),
    );
    if (mounted) _load();
  }

  void _setStatus(String? status) {
    setState(() => _status = status);
    _draw(fit: true);
  }

  // Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    final navSpace = widget.isMainTab && context.isCompact ? 76.0 : 0.0;
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
                      title: widget.userId == null ? 'แผนที่แปลง' : 'แปลงของสมาชิก',
                      subtitle: _loading ? 'กำลังโหลด' : '${_plots.length} แปลงในความดูแล',
                      onBack: widget.isMainTab ? null : () => Navigator.of(context).maybePop(),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'รายการแปลง',
                            onPressed: _plots.isEmpty ? null : _openList,
                            icon: const Icon(AppIcons.listBullets),
                          ),
                          IconButton(
                            tooltip: 'โหลดใหม่',
                            onPressed: _load,
                            icon: const Icon(AppIcons.refresh),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    _StatusFilter(
                      value: _status,
                      total: _plots.length,
                      pending: _count('PENDING'),
                      approved: _count('APPROVED'),
                      rejected: _count('REJECTED'),
                      onChanged: _setStatus,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: Space.lg,
            bottom: bottom + Space.lg + 64,
            child: Column(
              children: [
                if (!kIsWeb) ...[
                  MapFab(icon: AppIcons.locate, tooltip: 'ตำแหน่งของฉัน', onPressed: _locate),
                  const SizedBox(height: Space.sm),
                ],
                MapFab(icon: AppIcons.gridFour, tooltip: 'ดูทุกแปลง', onPressed: _fitAll),
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
                child: _loading
                    ? const _LoadingPill()
                    : _error != null
                        ? _ErrorCard(onRetry: _load)
                        : AppButton(
                            label: 'เพิ่มแปลงให้สมาชิก',
                            icon: AppIcons.add,
                            expand: true,
                            onPressed: _createPlot,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helpers ------------------------------------------------------------------

Map<String, dynamic>? _owner(Map<String, dynamic> plot) {
  final o = plot['owner'] ?? plot['user'];
  return o is Map && o.isNotEmpty ? Map<String, dynamic>.from(o) : null;
}

String _ownerName(Map<String, dynamic> plot) {
  final o = _owner(plot);
  if (o == null) return 'ไม่ระบุเจ้าของ';
  final full = (o['fullName'] as String?)?.trim();
  if (full != null && full.isNotEmpty) return full;
  final joined = '${o['firstName'] ?? ''} ${o['lastName'] ?? ''}'.trim();
  return joined.isEmpty ? 'ไม่ระบุเจ้าของ' : joined;
}

List<LatLng> _ring(Map<String, dynamic> plot) {
  final g = plot['geometry'];
  if (g is! Map) return const [];
  return PlotModel.fromJson({'name': '', 'geometry': Map<String, dynamic>.from(g)}).boundary;
}

LatLng _centroid(List<LatLng> ring) {
  var lat = 0.0, lng = 0.0;
  for (final p in ring) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / ring.length, lng / ring.length);
}

String _area(Object? value) {
  final v = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  return v >= 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(2);
}

String _place(Map<String, dynamic> plot) {
  final parts = [
    if ((plot['subDistrict'] ?? '').toString().isNotEmpty) 'ต.${plot['subDistrict']}',
    if ((plot['district'] ?? '').toString().isNotEmpty) 'อ.${plot['district']}',
    if ((plot['province'] ?? '').toString().isNotEmpty) 'จ.${plot['province']}',
  ];
  return parts.isEmpty ? '-' : parts.join(' ');
}

/// Whether [user] may edit or decide on [plot]. Super admins can act
/// anywhere; admins only inside their assigned territory, matched at the
/// most specific level they were given.
bool canManagePlot(UserModel? user, Map<String, dynamic> plot) {
  if (user == null) return false;
  if (user.role == UserRole.superAdmin) return true;
  if (user.role != UserRole.admin) return false;

  var where = plot;
  if (plot['province'] == null) where = _owner(plot) ?? plot;
  bool same(String? scope, Object? value) => scope != null && scope.isNotEmpty && value == scope;

  if ((user.subdistrict ?? '').isNotEmpty) return same(user.subdistrict, where['subDistrict']);
  if ((user.district ?? '').isNotEmpty) return same(user.district, where['district']);
  if ((user.province ?? '').isNotEmpty) return same(user.province, where['province']);
  if ((user.region ?? '').isNotEmpty) return same(user.region, where['region']);
  return false;
}

// Overlay pieces -------------------------------------------------------------

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.value,
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.onChanged,
  });

  final String? value;
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget chip(String? status, String label, int count, Color? dot) {
      final selected = value == status;
      return Pressable(
        onTap: () => onChanged(selected && status != null ? null : status),
        child: AnimatedContainer(
          duration: Motion.quick,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? p.ink : p.surface.withValues(alpha: 0.96),
            borderRadius: Radii.chip,
            border: Border.all(color: selected ? p.ink : p.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: context.text.labelLarge?.copyWith(
                  color: selected ? p.inkInverse : p.ink,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: context.text.labelMedium?.tabular.copyWith(
                  color: selected ? p.inkInverse.withValues(alpha: 0.7) : p.inkSubtle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          chip(null, 'ทั้งหมด', total, null),
          const SizedBox(width: Space.xs + 2),
          chip('PENDING', 'รอตรวจ', pending, MapStyles.colorFor('PENDING')),
          const SizedBox(width: Space.xs + 2),
          chip('APPROVED', 'อนุมัติ', approved, MapStyles.colorFor('APPROVED')),
          const SizedBox(width: Space.xs + 2),
          chip('REJECTED', 'ไม่ผ่าน', rejected, MapStyles.colorFor('REJECTED')),
        ],
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
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
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const FarmerMascot(size: 56, mood: MascotMood.think, animated: false),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('โหลดแปลงไม่สำเร็จ', style: context.text.titleSmall),
                Text('ตรวจสอบการเชื่อมต่อแล้วลองใหม่', style: context.text.bodySmall),
              ],
            ),
          ),
          IconButton(onPressed: onRetry, icon: const Icon(AppIcons.refresh), tooltip: 'ลองใหม่'),
        ],
      ),
    );
  }
}

// Plot list sheet ------------------------------------------------------------

class _PlotList extends StatefulWidget {
  const _PlotList({required this.plots});

  final List<Map<String, dynamic>> plots;

  @override
  State<_PlotList> createState() => _PlotListState();
}

class _PlotListState extends State<_PlotList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.plots
        : widget.plots.where((p) {
            final hay = '${p['name']} ${_ownerName(p)} ${p['district']} ${p['province']}'.toLowerCase();
            return hay.contains(q);
          }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.md),
          child: AppSearchField(
            hint: 'ชื่อแปลง เจ้าของ หรืออำเภอ',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Flexible(
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(Space.xl),
                  child: EmptyState(title: 'ไม่พบแปลง', message: 'ลองค้นหาด้วยคำอื่น', compact: true),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                  itemBuilder: (context, i) {
                    final plot = items[i];
                    final (label, tone) = StatusLabels.plot(plot['status'] as String?);
                    final ring = _ring(plot);
                    return AppCard(
                      padding: const EdgeInsets.all(Space.md),
                      onTap: () => Navigator.of(context).pop(plot),
                      child: Row(
                        children: [
                          PlotShape(points: ring, size: 44),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${plot['name'] ?? 'ไม่มีชื่อ'}',
                                  style: context.text.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_ownerName(plot)} · ${_area(plot['areaRai'])} ไร่',
                                  style: context.text.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          StatusBadge(label: label, tone: tone),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Plot detail sheet ----------------------------------------------------------

class _PlotSheet extends StatefulWidget {
  const _PlotSheet({required this.initial, required this.onChanged});

  final Map<String, dynamic> initial;
  final VoidCallback onChanged;

  @override
  State<_PlotSheet> createState() => _PlotSheetState();
}

class _PlotSheetState extends State<_PlotSheet> {
  late Map<String, dynamic> _plot = Map<String, dynamic>.from(widget.initial);
  bool _loadingDetail = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final service = context.read<AdminService>();
    try {
      final full = await service.getPlotDetail('${_plot['id']}');
      final ownerId = full['ownerId'] ?? full['userId'];
      if (_owner(full) == null && _owner(_plot) == null && ownerId != null) {
        try {
          full['owner'] = (await service.getUserDetails('$ownerId')).toJson();
        } on Object catch (e) {
          debugPrint('Owner lookup failed: $e');
        }
      }
      if (mounted && full.isNotEmpty) setState(() => _plot = {..._plot, ...full});
    } on Object catch (e) {
      debugPrint('Plot detail failed: $e');
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  String? get _ownerId => (_owner(_plot)?['id'] ?? _plot['ownerId'] ?? _plot['userId'])?.toString();

  Future<void> _approve() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'อนุมัติแปลงนี้?',
      message: 'เจ้าของแปลงจะได้รับการแจ้งเตือนทันที',
      confirmLabel: 'อนุมัติ',
      icon: AppIcons.checkCircle,
    );
    if (!ok || !mounted) return;
    await _decide(() => context.read<AdminService>().approvePlot(
          '${_plot['id']}',
          ownerId: _ownerId,
          plotName: _plot['name']?.toString(),
          adminId: context.read<AuthProvider>().currentUser?.id,
        ), 'APPROVED', 'อนุมัติแปลง ${_plot['name']} แล้ว');
  }

  Future<void> _reject() async {
    final reason = await AppDialogs.prompt(
      context,
      title: 'ไม่ผ่านการตรวจ',
      message: 'เหตุผลจะถูกส่งให้เจ้าของแปลงเพื่อแก้ไข',
      hint: 'เช่น ขอบเขตทับซ้อนพื้นที่สาธารณะ',
      confirmLabel: 'ส่งผลการตรวจ',
      destructive: true,
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    await _decide(() => context.read<AdminService>().rejectPlot(
          '${_plot['id']}',
          reason,
          ownerId: _ownerId,
          plotName: _plot['name']?.toString(),
          adminId: context.read<AuthProvider>().currentUser?.id,
        ), 'REJECTED', 'ส่งผลไม่ผ่านการตรวจแล้ว');
  }

  Future<void> _decide(Future<void> Function() call, String status, String done) async {
    setState(() => _busy = true);
    try {
      await call();
      if (!mounted) return;
      setState(() => _plot['status'] = status);
      widget.onChanged();
      Navigator.of(context).pop();
      AppToast.success(context, done);
    } on Object catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openInspection() {
    UserModel? owner;
    final o = _owner(_plot);
    if (o != null) {
      try {
        owner = UserModel.fromJson(o);
      } on Object catch (_) {}
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AdminGapInspectionScreen(
          plotId: '${_plot['id']}',
          plotName: '${_plot['name'] ?? 'ไม่ระบุชื่อ'}',
          owner: owner,
        ),
      ),
    );
  }

  Future<void> _edit() async {
    PlotModel model;
    try {
      model = PlotModel.fromJson(_plot);
    } on Object catch (_) {
      AppToast.error(context, 'ข้อมูลขอบเขตแปลงไม่สมบูรณ์');
      return;
    }
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MapDrawingScreen(plotToEdit: model, isAdmin: true)),
    );
    if (updated is PlotModel && mounted) {
      setState(() => _plot['geometry'] = updated.geometry);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().currentUser;
    final canManage = canManagePlot(user, _plot);
    final status = _plot['status'] as String?;
    final (label, tone) = StatusLabels.plot(status);
    final owner = _owner(_plot);
    final ring = _ring(_plot);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        Space.sm,
        Space.xl,
        Space.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PlotShape(points: ring, size: 56),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_plot['name'] ?? 'แปลงไม่มีชื่อ'}', style: context.text.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${_plot['species'] ?? 'ไม่ระบุสายพันธุ์'} · ${_area(_plot['areaRai'])} ไร่',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: Space.lg),
          AppCard(
            padding: const EdgeInsets.all(Space.md),
            color: p.surfaceSunken,
            borderColor: Colors.transparent,
            child: Row(
              children: [
                InitialsAvatar(name: _ownerName(_plot), size: 40),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loadingDetail && owner == null ? 'กำลังโหลดเจ้าของแปลง' : _ownerName(_plot),
                        style: context.text.titleSmall,
                      ),
                      Text(
                        '${owner?['phone'] ?? '-'} · ${_place(_plot)}',
                        style: context.text.bodySmall?.tabular,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!canManage && user?.role == UserRole.admin) ...[
            const SizedBox(height: Space.md),
            const InlineBanner(
              tone: Tone.info,
              title: 'อยู่นอกพื้นที่ที่คุณดูแล',
              message: 'ดูข้อมูลได้ แต่การอนุมัติและแก้ไขขอบเขตทำได้เฉพาะเจ้าหน้าที่ในพื้นที่',
            ),
          ],
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'รายงาน GAP',
                  icon: AppIcons.clipboard,
                  onPressed: _busy ? null : _openInspection,
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: Space.sm),
                AppIconButton(
                  icon: AppIcons.edit,
                  tooltip: 'แก้ไขขอบเขต',
                  onPressed: _busy ? null : _edit,
                ),
              ],
            ],
          ),
          if (status == 'PENDING' && canManage) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'ไม่ผ่าน',
                    onPressed: _busy ? null : _reject,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: AppButton(
                    label: 'อนุมัติ',
                    icon: AppIcons.check,
                    loading: _busy,
                    onPressed: _approve,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
