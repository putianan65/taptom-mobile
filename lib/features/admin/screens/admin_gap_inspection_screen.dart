import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/gap_service.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../gap/gap_categories.dart';
import '../../gap/gap_labels.dart';
import '../../gap/screens/plot_gallery_screen.dart';
import 'admin_plots_map_screen.dart' show canManagePlot;
import 'traceability_sheet.dart';

/// Staff review of one plot's GAP records: what has been filled in, the
/// records themselves, written guidance per category, the report PDF and
/// the approve or reject decision.
class AdminGapInspectionScreen extends StatefulWidget {
  const AdminGapInspectionScreen({
    super.key,
    required this.plotId,
    required this.plotName,
    this.owner,
  });

  final String plotId;
  final String plotName;
  final UserModel? owner;

  @override
  State<AdminGapInspectionScreen> createState() => _AdminGapInspectionScreenState();
}

class _AdminGapInspectionScreenState extends State<AdminGapInspectionScreen> {
  GapProgress _progress = GapProgress.empty;
  Map<String, dynamic> _plot = {};
  late UserModel? _owner = widget.owner;
  bool _loading = true;
  String? _error;
  bool _deciding = false;
  bool _exporting = false;

  String get _status => '${_plot['status'] ?? ''}'.toUpperCase();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final gap = context.read<GapService>();
    final admin = context.read<AdminService>();
    try {
      final results = await Future.wait([
        gap.getProgress(widget.plotId, force: true),
        admin.getPlotDetail(widget.plotId).then<Map<String, dynamic>?>((v) => v, onError: (_) => null),
      ]);
      final progress = results[0] as GapProgress;
      final plot = results[1] as Map<String, dynamic>? ?? {};
      var owner = _owner;
      final o = plot['owner'] ?? plot['user'];
      if (owner == null && o is Map && o.isNotEmpty) {
        try {
          owner = UserModel.fromJson(Map<String, dynamic>.from(o));
        } on Object catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _plot = plot;
        _owner = owner;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'โหลดข้อมูล GAP ไม่สำเร็จ';
      });
    }
  }

  // Actions ------------------------------------------------------------------

  Future<void> _decide({required bool approve}) async {
    String? reason;
    if (approve) {
      final ok = await AppDialogs.confirm(
        context,
        title: 'อนุมัติแปลง ${widget.plotName}?',
        message: _progress.isComplete
            ? 'ข้อมูล GAP ครบทั้ง 7 หมวด เจ้าของแปลงจะได้รับการแจ้งเตือน'
            : 'ข้อมูล GAP ยังไม่ครบ (${_progress.completed}/7 หมวด) ยืนยันที่จะอนุมัติหรือไม่',
        confirmLabel: 'อนุมัติ',
        icon: AppIcons.checkCircle,
      );
      if (!ok) return;
    } else {
      reason = await AppDialogs.prompt(
        context,
        title: 'ไม่ผ่านการตรวจ',
        message: 'อธิบายสิ่งที่ต้องแก้ไข เจ้าของแปลงจะเห็นข้อความนี้',
        hint: 'เช่น ขอบเขตแปลงทับซ้อนพื้นที่สาธารณะ',
        confirmLabel: 'ส่งผลการตรวจ',
        destructive: true,
      );
      if (reason == null || reason.isEmpty) return;
    }
    if (!mounted) return;

    final service = context.read<AdminService>();
    final me = context.read<AuthProvider>().currentUser;
    setState(() => _deciding = true);
    try {
      if (approve) {
        await service.approvePlot(widget.plotId, ownerId: _owner?.id, plotName: widget.plotName, adminId: me?.id);
      } else {
        await service.rejectPlot(widget.plotId, reason!, ownerId: _owner?.id, plotName: widget.plotName, adminId: me?.id);
      }
      if (!mounted) return;
      AppToast.success(context, approve ? 'อนุมัติแปลงแล้ว' : 'ส่งผลการตรวจแล้ว');
      await _load();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  Future<void> _feedback(GapCategory c) async {
    final message = await AppDialogs.prompt(
      context,
      title: 'คำแนะนำหมวด ${c.code}',
      message: '${c.title} · เกษตรกรจะได้รับเป็นการแจ้งเตือน',
      hint: 'เช่น ระบุเลขทะเบียนสารเคมีให้ครบทุกรายการ',
      confirmLabel: 'ส่งคำแนะนำ',
    );
    if (message == null || message.isEmpty || !mounted) return;
    try {
      await context.read<AdminService>().submitGapFeedback(
            plotId: widget.plotId,
            categoryKey: c.name,
            message: message,
          );
      if (mounted) AppToast.success(context, 'ส่งคำแนะนำแล้ว');
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _report({required bool share}) async {
    setState(() => _exporting = true);
    try {
      final plot = _plot.isNotEmpty ? _plot : await context.read<AdminService>().getPlotDetail(widget.plotId);
      final bytes = await PdfGeneratorService().generateGapReport(
        plot: plot,
        owner: _owner?.toJson(),
        summaryData: _progress.reportSummary(),
      );
      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'GAP-${widget.plotName.replaceAll(' ', '_')}.pdf',
        );
      } else {
        await Printing.layoutPdf(onLayout: (_) => bytes, name: 'GAP-${widget.plotName}');
      }
    } on Object catch (e) {
      if (mounted) AppToast.error(context, 'สร้างรายงานไม่สำเร็จ: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _open(GapCategory c) {
    if (c == GapCategory.traceability) {
      showAppSheet<void>(
        context,
        title: 'ล็อตผลผลิต',
        subtitle: widget.plotName,
        expand: true,
        child: TraceabilityManagementSheet(plotId: widget.plotId),
      );
      return;
    }
    showAppSheet<void>(
      context,
      title: '${c.code} ${c.title}',
      subtitle: GapLabels.summary(c, _progress),
      expand: true,
      child: _CategoryRecords(category: c, progress: _progress, plotName: widget.plotName),
    );
  }

  void _gallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlotGalleryScreen(plotId: widget.plotId, plotName: widget.plotName, isReadOnly: true),
      ),
    );
  }

  // Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final me = context.watch<AuthProvider>().currentUser;
    final canDecide = _status == 'PENDING' && canManagePlot(me, {..._plot, if (_owner != null) 'owner': _owner!.toJson()});

    return PageScaffold(
      title: widget.plotName,
      subtitle: _owner?.fullName ?? 'ตรวจข้อมูล GAP',
      onRefresh: _load,
      actions: [
        AppIconButton(icon: AppIcons.gallery, tooltip: 'รูปถ่ายแปลง', onPressed: _gallery),
        const SizedBox(width: Space.sm),
      ],
      bottomBar: canDecide && !_loading
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(top: BorderSide(color: p.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'ไม่ผ่าน',
                        onPressed: _deciding ? null : () => _decide(approve: false),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'อนุมัติแปลง',
                        icon: AppIcons.check,
                        loading: _deciding,
                        onPressed: () => _decide(approve: true),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      slivers: [
        if (_loading)
          const SliverToBoxAdapter(child: SkeletonList(count: 5, thumbnail: false))
        else if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else ...[
          SliverToBoxAdapter(child: _Overview(progress: _progress, owner: _owner, plot: _plot).entrance(context)),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
          const SliverToBoxAdapter(child: SectionHeader(title: 'บันทึก 7 หมวด')),
          SliverToBoxAdapter(
            child: ListGroup(
              children: [
                for (final c in GapCategory.values)
                  _CategoryRow(
                    category: c,
                    done: _progress.isDone(c),
                    summary: GapLabels.summary(c, _progress),
                    onTap: _progress.isDone(c) ? () => _open(c) : null,
                    onFeedback: me?.isStaff == true ? () => _feedback(c) : null,
                  ),
              ],
            ).entrance(context, index: 1),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
          const SliverToBoxAdapter(child: SectionHeader(title: 'รายงาน')),
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'ดูตัวอย่าง',
                    icon: AppIcons.eye,
                    onPressed: _progress.completed == 0 || _exporting ? null : () => _report(share: false),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: AppButton.tonal(
                    label: 'แชร์ PDF',
                    icon: AppIcons.share,
                    loading: _exporting,
                    onPressed: _progress.completed == 0 ? null : () => _report(share: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.progress, required this.owner, required this.plot});

  final GapProgress progress;
  final UserModel? owner;
  final Map<String, dynamic> plot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, tone) = StatusLabels.plot(plot['status'] as String?);
    final updated = progress.lastUpdated;
    final readiness = progress.isComplete
        ? ('ครบทุกหมวด พร้อมพิจารณา', Tone.success)
        : progress.completed >= 5
            ? ('ใกล้ครบ ขาดอีก ${7 - progress.completed} หมวด', Tone.warning)
            : ('ยังขาดอีก ${7 - progress.completed} หมวด', Tone.danger);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProgressRing(
                value: progress.ratio,
                size: 76,
                child: Text('${progress.completed}/7', style: context.text.titleMedium?.tabular),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(readiness.$1, style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      updated == null ? 'ยังไม่มีการบันทึก' : 'บันทึกล่าสุด ${ThaiDate.relative(updated)}',
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: Space.sm),
                    StatusBadge(label: label, tone: tone),
                  ],
                ),
              ),
            ],
          ),
          if (owner != null) ...[
            const SizedBox(height: Space.lg),
            Divider(height: 1, color: p.line),
            const SizedBox(height: Space.md),
            Row(
              children: [
                InitialsAvatar(name: owner!.fullName, photoUrl: owner!.photoUrl, size: 40),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner!.fullName, style: context.text.titleSmall),
                      Text(
                        [owner!.phone, if ((owner!.district ?? '').isNotEmpty) 'อ.${owner!.district}'].join(' · '),
                        style: context.text.bodySmall?.tabular,
                      ),
                    ],
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.done,
    required this.summary,
    this.onTap,
    this.onFeedback,
  });

  final GapCategory category;
  final bool done;
  final String summary;
  final VoidCallback? onTap;
  final VoidCallback? onFeedback;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.xs, Space.md),
        child: Row(
          children: [
            IconTile(icon: category.icon, tone: done ? Tone.brand : Tone.neutral, size: 40),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.code}  ${category.title}',
                    style: context.text.titleSmall?.copyWith(color: done ? p.ink : p.inkMuted),
                  ),
                  Text(
                    summary,
                    style: context.text.bodySmall?.copyWith(color: done ? p.inkMuted : p.inkSubtle),
                  ),
                ],
              ),
            ),
            Icon(
              done ? AppIcons.checkCircleFill : AppIcons.pending,
              size: 18,
              color: done ? p.success : p.inkSubtle,
            ),
            if (onFeedback != null)
              IconButton(
                tooltip: 'ส่งคำแนะนำหมวดนี้',
                onPressed: onFeedback,
                icon: Icon(AppIcons.chat, size: 20, color: p.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRecords extends StatelessWidget {
  const _CategoryRecords({required this.category, required this.progress, required this.plotName});

  final GapCategory category;
  final GapProgress progress;
  final String plotName;

  @override
  Widget build(BuildContext context) {
    final bottom = Space.xl + MediaQuery.paddingOf(context).bottom;
    if (category == GapCategory.general) {
      final rows = GapLabels.general(progress.general ?? const {}, plotName: plotName);
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, bottom),
        child: ListGroup(
          children: [for (final (k, v) in rows) KeyValueRow(label: k, value: v)],
        ),
      );
    }
    final items = progress.items(category);
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(Space.xl),
        child: EmptyState(title: 'ยังไม่มีบันทึกในหมวดนี้', compact: true),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, bottom),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is! Map) return const SizedBox.shrink();
        return _RecordCard(entry: GapLabels.entry(category, item, i), icon: category.icon);
      },
    );
  }
}

class _RecordCard extends StatefulWidget {
  const _RecordCard({required this.entry, required this.icon});

  final GapEntry entry;
  final IconData icon;

  @override
  State<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final e = widget.entry;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: e.fields.isEmpty ? null : () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.md + 2),
            child: Row(
              children: [
                IconTile(icon: widget.icon, size: 36),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: context.text.titleSmall),
                      if ((e.subtitle ?? '').isNotEmpty && e.subtitle != '-')
                        Text(e.subtitle!, style: context.text.bodySmall),
                    ],
                  ),
                ),
                if (e.fields.isNotEmpty)
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: Motion.base,
                    child: Icon(AppIcons.chevronDown, size: 18, color: p.inkSubtle),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.standard,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(Space.md + 2, 0, Space.md + 2, Space.md),
                    child: Column(
                      children: [
                        Divider(height: 1, color: p.line),
                        const SizedBox(height: Space.sm),
                        for (final (k, v) in e.fields) KeyValueRow(label: k, value: v),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
