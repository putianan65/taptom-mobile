import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/traceability_service.dart';
import '../../../core/utils/geo_json_utils.dart';
import '../../../core/utils/map_styles.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/trace_report.dart';
import '../../gap/gap_labels.dart';

/// Public farm-to-package report for one lot, opened from the QR code on
/// the package. No sign-in needed. Shows the grower by name and district
/// only; contact details stay private.
class TraceabilityReportScreen extends StatefulWidget {
  const TraceabilityReportScreen({super.key, required this.lotNumber});

  final String lotNumber;

  @override
  State<TraceabilityReportScreen> createState() => _TraceabilityReportScreenState();
}

class _TraceabilityReportScreenState extends State<TraceabilityReportScreen> {
  TraceReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await TraceabilityService().getTraceabilityReport(widget.lotNumber);
      if (mounted) setState(() => _report = TraceReport.fromJson(r, lotNumber: widget.lotNumber));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException && e.isNotFound
          ? 'ไม่พบล็อต ${widget.lotNumber} ตรวจสอบรหัสบนบรรจุภัณฑ์อีกครั้ง'
          : 'โหลดข้อมูลไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วลองใหม่');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = _report;
    if (r == null) {
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(backgroundColor: p.background, surfaceTintColor: Colors.transparent),
        body: _error == null
            ? const Padding(padding: EdgeInsets.all(Space.xl), child: SkeletonList(count: 4, thumbnail: false))
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(Space.xl),
                  child: EmptyState(
                    title: 'เปิดรายงานไม่ได้',
                    message: _error,
                    mood: MascotMood.think,
                    actionLabel: 'ลองใหม่',
                    onAction: _load,
                  ),
                ),
              ),
      );
    }

    final ring = r.geometry == null ? <LatLng>[] : GeoJsonUtils.fromPolygon(r.geometry!);
    final certified = r.certified;
    final lotNumber = r.lotNumber;
    final place = r.place;
    final area = r.areaRai;

    return Scaffold(
      backgroundColor: p.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HeroHeader(
              minHeight: 220,
              trailing: FarmerMascot(size: context.isCompact ? 96 : 120, mood: certified ? MascotMood.joy : MascotMood.happy),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        AppIconButton(
                          icon: AppIcons.back,
                          tooltip: 'ย้อนกลับ',
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      else
                        const LogoMark(size: 36),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  Text(
                    'ตรวจสอบย้อนกลับ',
                    style: context.text.labelLarge?.copyWith(color: p.heroInk.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 2),
                  // API lot numbers run to 27 characters; keep them on one line.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(lotNumber, style: context.text.headlineMedium?.mono.copyWith(color: p.heroInk)),
                  ),
                  const SizedBox(height: Space.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: certified ? p.heroInk : p.heroInk.withValues(alpha: 0.14),
                      borderRadius: Radii.chip,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(certified ? AppIcons.gap : AppIcons.pending, size: 16, color: certified ? p.hero : p.heroInk),
                        const SizedBox(width: 6),
                        Text(
                          certified ? 'แปลงผ่านมาตรฐาน GAP' : 'แปลงอยู่ระหว่างการรับรอง',
                          style: context.text.labelMedium?.copyWith(color: certified ? p.hero : p.heroInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SheetContainer(
              child: ContentWidth(
                padding: EdgeInsets.fromLTRB(context.pageGutter, Space.xs, context.pageGutter, Space.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('ผลผลิต', style: context.text.labelMedium),
                          const SizedBox(height: 4),
                          Text('ใบกระท่อม', style: context.text.titleLarge),
                          const SizedBox(height: Space.md),
                          Row(
                            children: [
                              Expanded(
                                child: _Fact(
                                  label: 'ปริมาณ',
                                  value: r.quantity == null ? '-' : '${r.quantity} ${GapLabels.unit(r.unit)}',
                                ),
                              ),
                              Expanded(
                                child: _Fact(
                                  label: 'วันเก็บเกี่ยว',
                                  value: ThaiDate.short(r.harvestDate),
                                ),
                              ),
                              if (r.grade != null)
                                Expanded(child: _Fact(label: 'เกรด', value: GapLabels.value('qualityGrade', r.grade))),
                            ],
                          ),
                        ],
                      ),
                    ).entrance(context),
                    const SizedBox(height: Space.xxl),
                    const SectionHeader(title: 'แหล่งที่ปลูก'),
                    AppCard(
                      padding: EdgeInsets.zero,
                      clip: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (ring.length >= 3) SizedBox(height: 200, child: _OriginMap(ring: ring)),
                          Padding(
                            padding: const EdgeInsets.all(Space.lg),
                            child: Column(
                              children: [
                                KeyValueRow(label: 'แปลง', value: r.plotName ?? '-'),
                                KeyValueRow(label: 'ที่ตั้ง', value: place.isEmpty ? '-' : place),
                                if (area != null) KeyValueRow(label: 'พื้นที่', value: ThaiArea.fromSqm(r.areaSqm!).toString()),
                                if (r.species != null) KeyValueRow(label: 'สายพันธุ์', value: r.species!),
                                KeyValueRow(label: 'ผู้ปลูก', value: r.farmerName ?? '-'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).entrance(context, index: 1),
                    const SizedBox(height: Space.xxl),
                    const SectionHeader(title: 'มาตรฐานการผลิต'),
                    ListGroup(
                      children: [
                        KeyValueRow(label: 'สถานะ GAP', value: certified ? 'รับรองแล้ว' : 'ระหว่างตรวจ'),
                        if (r.season != null) KeyValueRow(label: 'รอบการผลิต', value: r.season!),
                        if (r.gapUpdatedAt != null)
                          KeyValueRow(label: 'บันทึกล่าสุด', value: ThaiDate.long(r.gapUpdatedAt)),
                      ],
                    ).entrance(context, index: 2),
                    if (r.inputs.isNotEmpty) ...[
                      const SizedBox(height: Space.xxl),
                      const SectionHeader(title: 'ปัจจัยการผลิตที่ใช้', subtitle: 'ตามที่เกษตรกรบันทึกไว้'),
                      ListGroup(
                        children: [
                          for (final c in r.inputs)
                            ListRow(
                              icon: c['type'] == 'PESTICIDE' ? AppIcons.safety : AppIcons.inputs,
                              title: '${c['name'] ?? c['productName'] ?? '-'}',
                              subtitle: [
                                GapLabels.value('type', c['type']),
                                if (c['amount'] != null) '${c['amount']} ${GapLabels.unit(c['unit'])}',
                                if ((c['usedDate'] ?? c['usageDate']) != null)
                                  ThaiDate.short(DateTime.tryParse('${c['usedDate'] ?? c['usageDate']}')),
                              ].where((s) => s.isNotEmpty && s != '-').join(' · '),
                              showChevron: false,
                              dense: true,
                            ),
                        ],
                      ).entrance(context, index: 3),
                    ],
                    const SizedBox(height: Space.x3),
                    Center(
                      child: Column(
                        children: [
                          const LogoMark(size: 32),
                          const SizedBox(height: Space.sm),
                          Text(
                            'ข้อมูลบันทึกผ่านระบบ TAPTOM และตรวจโดยเจ้าหน้าที่ในพื้นที่',
                            style: context.text.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Space.xl),
                          const DevelopedBy(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: context.text.titleSmall?.tabular),
      ],
    );
  }
}

class _OriginMap extends StatefulWidget {
  const _OriginMap({required this.ring});

  final List<LatLng> ring;

  @override
  State<_OriginMap> createState() => _OriginMapState();
}

class _OriginMapState extends State<_OriginMap> {
  MapLibreMapController? _c;

  Future<void> _draw() async {
    final c = _c;
    final ring = widget.ring;
    if (c == null) return;
    try {
      await c.addFill(FillOptions(geometry: [[...ring, ring.first]], fillColor: MapStyles.plotFill, fillOutlineColor: MapStyles.plotFill, fillOpacity: 0.4));
      await c.addLine(LineOptions(geometry: [...ring, ring.first], lineColor: '#FFFFFF', lineWidth: 2));
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
          left: 40,
          right: 40,
          top: 40,
          bottom: 40,
        ),
      );
    } on Object catch (e) {
      debugPrint('Origin map overlay failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: context.palette.hero),
        IgnorePointer(
          child: MapLibreMap(
            styleString: MapStyles.satellite,
            initialCameraPosition: CameraPosition(target: widget.ring.first, zoom: 15),
            compassEnabled: false,
            trackCameraPosition: false,
            onMapCreated: (c) => _c = c,
            onStyleLoadedCallback: _draw,
          ),
        ),
      ],
    );
  }
}
