import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/gap_service.dart';
import '../../../core/services/plot_service.dart';
import '../../../core/utils/geo_json_utils.dart';
import '../../../core/utils/map_styles.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../../auth/auth_provider.dart';
import '../../certificate/screens/certificate_viewer_screen.dart';
import '../../gap/gap_categories.dart';
import '../../gap/gap_labels.dart';
import '../../gap/screens/forms/gap_traceability_form.dart';
import '../../gap/screens/gap_main_screen.dart';
import '../../gap/screens/plot_gallery_screen.dart';
import 'map_drawing_screen.dart';

/// One of the member's plots: where it is, how far its GAP records are,
/// and what to do next. Approved plots are read-only and show the
/// certificate; others can be renamed, redrawn or removed.
///
/// Pops with `true` when the plot changed so lists can refresh.
class PlotDetailScreen extends StatefulWidget {
  const PlotDetailScreen({super.key, required this.plot});

  final PlotModel plot;

  @override
  State<PlotDetailScreen> createState() => _PlotDetailScreenState();
}

class _PlotDetailScreenState extends State<PlotDetailScreen> {
  late PlotModel _plot = widget.plot;
  GapProgress? _progress;
  bool _changed = false;

  bool get _approved => _plot.status == 'APPROVED';
  String get _id => _plot.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress({bool force = false}) async {
    if (_id.isEmpty) return;
    try {
      final p = await context.read<GapService>().getProgress(_id, force: force);
      if (mounted) setState(() => _progress = p);
    } on Object catch (_) {
      if (mounted) setState(() => _progress = GapProgress.empty);
    }
  }

  Future<void> _reloadPlot() async {
    try {
      final fresh = await context.read<PlotService>().getPlot(_id);
      if (mounted) setState(() => _plot = fresh);
    } on Object catch (_) {}
  }

  // Actions ------------------------------------------------------------------

  Future<void> _openGap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GapMainScreen(plotId: _id, plotName: _plot.name),
      ),
    );
    _loadProgress(force: true);
  }

  void _openLots() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GapTraceabilityForm(plotId: _id, isReadOnly: _approved),
      ),
    );
  }

  void _openCertificate() {
    final owner = _plot.ownerName ?? context.read<AuthProvider>().currentUser?.fullName ?? 'เกษตรกร';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificateViewerScreen(plot: _plot, ownerName: owner),
      ),
    );
  }

  void _openGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlotGalleryScreen(plotId: _id, plotName: _plot.name, isReadOnly: _approved),
      ),
    );
  }

  Future<void> _editInfo() async {
    final data = await showAppSheet<Map<String, dynamic>>(
      context,
      title: 'แก้ไขข้อมูลแปลง',
      child: _InfoForm(plot: _plot),
    );
    if (data == null || !mounted) return;
    try {
      final updated = await context.read<PlotService>().updatePlot(_id, data);
      if (!mounted) return;
      setState(() {
        _plot = _plot.copyWith(name: updated.name, species: updated.species);
        _changed = true;
      });
      AppToast.success(context, 'บันทึกข้อมูลแปลงแล้ว');
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _redraw() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MapDrawingScreen(plotToEdit: _plot)));
    if (!mounted) return;
    if (result is PlotModel) {
      setState(() {
        _plot = _plot.copyWith(geometry: result.geometry, areaRai: result.areaRai ?? _plot.areaRai);
        _changed = true;
      });
    } else if (result != null) {
      _changed = true;
      _reloadPlot();
    }
  }

  Future<void> _delete() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ลบแปลง ${_plot.name}?',
      message: 'ข้อมูล GAP ทั้งหมดของแปลงนี้จะถูกลบด้วย และกู้คืนไม่ได้',
      confirmLabel: 'ลบแปลง',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<PlotService>().deletePlot(_id);
      GapService.invalidate(_id);
      if (!mounted) return;
      AppToast.success(context, 'ลบแปลงแล้ว');
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (statusLabel, statusTone) = StatusLabels.plot(_plot.status);
    final area = _plot.areaRai ?? ThaiArea.fromSqm(GeoJsonUtils.areaSqm(_plot.boundary)).inRai;
    final gutter = context.pageGutter;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: p.background,
        body: RefreshIndicator(
          color: p.brand,
          onRefresh: () async {
            await Future.wait([_reloadPlot(), _loadProgress(force: true)]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                backgroundColor: p.hero,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: AppIconButton(
                      icon: AppIcons.back,
                      tooltip: 'ย้อนกลับ',
                      onPressed: () => Navigator.of(context).pop(_changed),
                    ),
                  ),
                ),
                title: Text(_plot.name, style: context.text.titleMedium?.copyWith(color: p.heroInk)),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _MapHeader(plot: _plot),
                ),
              ),
              SliverToBoxAdapter(
                child: ContentWidth(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    Space.xl,
                    gutter,
                    Space.x5 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(_plot.name, style: context.text.headlineMedium)),
                          StatusBadge(label: statusLabel, tone: statusTone),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          _plot.species ?? 'ไม่ระบุสายพันธุ์',
                          [
                            if ((_plot.subDistrict ?? '').isNotEmpty) 'ต.${_plot.subDistrict}',
                            if ((_plot.district ?? '').isNotEmpty) 'อ.${_plot.district}',
                          ].join(' '),
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
                      ),
                      const SizedBox(height: Space.xl),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StatTile(
                                value: area,
                                decimals: area % 1 == 0 ? 0 : 1,
                                label: 'พื้นที่ (ไร่)',
                                icon: AppIcons.area,
                                dense: true,
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: StatTile(
                                value: _plot.ageInDays,
                                label: 'วันในระบบ',
                                icon: AppIcons.calendar,
                                dense: true,
                              ),
                            ),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: StatTile(
                                value: _plot.treeCount ?? 0,
                                label: 'จำนวนต้น',
                                icon: AppIcons.tree,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ).entrance(context),
                      const SizedBox(height: Space.xxl),
                      if (_approved)
                        _CertificateCard(onView: _openCertificate, onLots: _openLots).entrance(context, index: 1)
                      else
                        _GapCard(progress: _progress, onOpen: _openGap).entrance(context, index: 1),
                      const SizedBox(height: Space.xxl),
                      const SectionHeader(title: 'จัดการแปลง'),
                      ListGroup(
                        children: [
                          if (_approved)
                            ListRow(
                              icon: AppIcons.records,
                              title: 'ดูบันทึก GAP',
                              subtitle: 'อ่านอย่างเดียวหลังได้รับการรับรอง',
                              onTap: _openGap,
                            ),
                          ListRow(
                            icon: AppIcons.gallery,
                            title: 'รูปถ่ายแปลง',
                            subtitle: 'หลักฐานประกอบการตรวจ',
                            onTap: _openGallery,
                          ),
                          if (!_approved) ...[
                            ListRow(icon: AppIcons.edit, title: 'แก้ไขชื่อและสายพันธุ์', onTap: _editInfo),
                            ListRow(icon: AppIcons.path, title: 'แก้ไขขอบเขตบนแผนที่', onTap: _redraw),
                            ListRow(icon: AppIcons.delete, title: 'ลบแปลงนี้', destructive: true, onTap: _delete),
                          ],
                        ],
                      ).entrance(context, index: 2),
                      if (_approved) ...[
                        const SizedBox(height: Space.md),
                        Text(
                          'แปลงที่ได้รับการรับรองแล้วแก้ไขหรือลบไม่ได้ หากข้อมูลไม่ถูกต้อง ติดต่อเจ้าหน้าที่ในพื้นที่',
                          style: context.text.bodySmall,
                        ),
                      ],
                      if ((_progress?.activities ?? const []).isNotEmpty) ...[
                        const SizedBox(height: Space.xxl),
                        const SectionHeader(title: 'กิจกรรมล่าสุดในแปลง'),
                        _Activities(items: _progress!.activities),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapHeader extends StatefulWidget {
  const _MapHeader({required this.plot});

  final PlotModel plot;

  @override
  State<_MapHeader> createState() => _MapHeaderState();
}

class _MapHeaderState extends State<_MapHeader> {
  MapLibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ring = widget.plot.boundary;
    final center = ring.isEmpty
        ? MapStyles.thailand.target
        : LatLng(
            ring.map((e) => e.latitude).reduce((a, b) => a + b) / ring.length,
            ring.map((e) => e.longitude).reduce((a, b) => a + b) / ring.length,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.hero),
        if (ring.length >= 3)
          IgnorePointer(
            child: MapLibreMap(
              styleString: MapStyles.satellite,
              initialCameraPosition: CameraPosition(target: center, zoom: 16),
              compassEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              trackCameraPosition: false,
              onMapCreated: (c) => _controller = c,
              onStyleLoadedCallback: () => _draw(ring),
            ),
          ),
        // Keeps the back button and title legible over bright imagery.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.35, 1],
              colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent, Colors.black.withValues(alpha: 0.15)],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _draw(List<LatLng> ring) async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.addFill(
        FillOptions(
          geometry: [
            [...ring, ring.first],
          ],
          fillColor: MapStyles.plotFill,
          fillOutlineColor: MapStyles.plotFill,
          fillOpacity: 0.35,
        ),
      );
      await c.addLine(LineOptions(geometry: [...ring, ring.first], lineColor: '#FFFFFF', lineWidth: 2.5));
      var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (final p in ring) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLng = math.min(minLng, p.longitude);
        maxLng = math.max(maxLng, p.longitude);
      }
      await c.moveCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
          left: 48,
          right: 48,
          top: 96,
          bottom: 48,
        ),
      );
    } on Object catch (e) {
      debugPrint('Plot header overlay failed: $e');
    }
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.progress, required this.onOpen});

  final GapProgress? progress;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final g = progress;
    if (g == null) return const SkeletonBox(height: 168, radius: Radii.lg);
    final next = g.next;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProgressRing(
                value: g.ratio,
                size: 72,
                child: Text('${g.completed}/7', style: context.text.titleMedium?.tabular),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.isComplete ? 'บันทึกครบทุกหมวดแล้ว' : 'ความคืบหน้าบันทึก GAP',
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next == null ? 'รอเจ้าหน้าที่ตรวจประเมิน' : 'ถัดไป: ${next.code} ${next.title}',
                      style: context.text.bodySmall,
                    ),
                    if (g.lastUpdated != null)
                      Text(
                        'บันทึกล่าสุด ${ThaiDate.relative(g.lastUpdated)}',
                        style: context.text.labelSmall?.copyWith(color: p.inkSubtle),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in GapCategory.values)
                Tooltip(
                  message: c.title,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: g.isDone(c) ? p.brandSoft : p.surface,
                      borderRadius: Radii.chip,
                      border: Border.all(color: g.isDone(c) ? Colors.transparent : p.line),
                    ),
                    child: Text(
                      c.code,
                      style: context.text.labelMedium?.tabular.copyWith(
                        color: g.isDone(c) ? p.brandStrong : p.inkSubtle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          AppButton(
            label: next == null ? 'ดูบันทึก GAP' : 'บันทึก GAP ต่อ',
            icon: AppIcons.records,
            expand: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.onView, required this.onLots});

  final VoidCallback onView;
  final VoidCallback onLots;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: p.hero,
            padding: const EdgeInsets.all(Space.xl),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: p.heroInk.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(AppIcons.certificate, color: p.heroInk, size: 28),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผ่านมาตรฐาน GAP', style: context.text.titleLarge?.copyWith(color: p.heroInk)),
                      Text(
                        'แปลงนี้ได้รับการรับรองแล้ว',
                        style: context.text.bodySmall?.copyWith(color: p.heroInk.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(label: 'ใบรับรอง', icon: AppIcons.certificate, onPressed: onView),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: AppButton.secondary(label: 'QR ล็อต', icon: AppIcons.qr, onPressed: onLots),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Activities extends StatelessWidget {
  const _Activities({required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    final recent = items.whereType<Map>().take(5).toList();
    return ListGroup(
      children: [
        for (final (i, item) in recent.indexed)
          Builder(
            builder: (context) {
              final e = GapLabels.entry(GapCategory.management, item, i);
              return ListRow(
                icon: AppIcons.fieldWork,
                title: e.title,
                subtitle: e.subtitle,
                showChevron: false,
                dense: true,
              );
            },
          ),
      ],
    );
  }
}

class _InfoForm extends StatefulWidget {
  const _InfoForm({required this.plot});

  final PlotModel plot;

  @override
  State<_InfoForm> createState() => _InfoFormState();
}

class _InfoFormState extends State<_InfoForm> {
  late final _name = TextEditingController(text: widget.plot.name);
  late final _species = TextEditingController(text: widget.plot.species);

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    super.dispose();
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
          AppTextField(label: 'ชื่อแปลง', controller: _name, onChanged: (_) => setState(() {})),
          const SizedBox(height: Space.lg),
          AppTextField(label: 'สายพันธุ์', controller: _species, hint: 'เช่น กระท่อมพันธุ์ก้านแดง'),
          const SizedBox(height: Space.xl),
          AppButton(
            label: 'บันทึก',
            expand: true,
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop({
                    'name': _name.text.trim(),
                    if (_species.text.trim().isNotEmpty) 'species': _species.text.trim(),
                  }),
          ),
        ],
      ),
    );
  }
}
