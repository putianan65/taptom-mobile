import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/gap_service.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../gap_categories.dart';
import '../gap_labels.dart';

/// Everything recorded for a plot on one page, as an officer would read
/// it, with tools to clear a category or start the plot over.
class GapSummaryScreen extends StatefulWidget {
  const GapSummaryScreen({super.key, required this.plotId, required this.plotName, this.readOnly = false});

  final String plotId;
  final String plotName;
  final bool readOnly;

  @override
  State<GapSummaryScreen> createState() => _GapSummaryScreenState();
}

class _GapSummaryScreenState extends State<GapSummaryScreen> {
  GapProgress? _progress;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await context.read<GapService>().getProgress(widget.plotId, force: true);
      if (mounted) setState(() => _progress = p);
    } on Object catch (e) {
      if (mounted) setState(() => _error = ErrorUtils.getReadableError(e));
    }
  }

  Future<void> _clear(GapCategory c) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ล้างข้อมูลหมวด ${c.code}?',
      message: 'บันทึกทั้งหมดใน${c.title}ของแปลงนี้จะถูกลบ และกู้คืนไม่ได้',
      confirmLabel: 'ล้างหมวดนี้',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final gap = context.read<GapService>();
    final progress = _progress ?? GapProgress.empty;
    final id = widget.plotId;
    String rid(dynamic r) => '${(r as Map)['id']}';

    setState(() => _busy = true);
    try {
      switch (c) {
        case GapCategory.general:
          await gap.deleteGeneralInfo(id);
        case GapCategory.inputs:
          for (final r in progress.inputs) {
            await gap.deleteInput(id, rid(r));
          }
        case GapCategory.management:
          for (final r in progress.activities) {
            await gap.deleteActivity(id, rid(r));
          }
        case GapCategory.harvest:
          for (final r in progress.harvests) {
            await gap.deleteHarvest(id, rid(r));
          }
        case GapCategory.postHarvest:
          for (final r in progress.postHarvests) {
            final harvestId = '${(r as Map)['harvestId'] ?? ''}';
            if (harvestId.isNotEmpty) await gap.deletePostHarvest(harvestId, rid(r));
          }
        case GapCategory.safety:
          for (final r in progress.trainings) {
            await gap.deleteTraining(id, rid(r));
          }
        case GapCategory.traceability:
          break;
      }
      GapService.invalidate(id);
      if (mounted) AppToast.success(context, 'ล้างข้อมูลหมวด ${c.code} แล้ว');
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
      _load();
    }
  }

  Future<void> _reset() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'เริ่มบันทึกแปลงนี้ใหม่?',
      message: 'ข้อมูล GAP ทุกหมวดของ ${widget.plotName} จะถูกลบ ใช้เมื่อบันทึกผิดแปลงหรือต้องการเริ่มรอบใหม่',
      confirmLabel: 'ลบทั้งหมด',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<GapService>().resetGapData(widget.plotId);
      GapService.invalidate(widget.plotId);
      if (mounted) AppToast.success(context, 'ล้างข้อมูลทั้งหมดแล้ว');
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final g = _progress;

    return PageScaffold(
      title: 'สรุปข้อมูล GAP',
      subtitle: widget.plotName,
      onRefresh: _load,
      actions: [
        if (!widget.readOnly)
          PopupMenuButton<String>(
            tooltip: 'ตัวเลือก',
            icon: Icon(AppIcons.more, color: p.ink),
            enabled: !_busy,
            onSelected: (_) => _reset(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reset',
                child: Text('ลบข้อมูล GAP ทั้งหมด', style: TextStyle(color: p.danger)),
              ),
            ],
          ),
        const SizedBox(width: Space.sm),
      ],
      slivers: [
        if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else if (g == null)
          const SliverToBoxAdapter(child: SkeletonList(count: 5, thumbnail: false))
        else ...[
          SliverToBoxAdapter(
            child: AppCard(
              child: Row(
                children: [
                  ProgressRing(
                    value: g.ratio,
                    size: 64,
                    child: Text('${g.completed}/7', style: context.text.titleSmall?.tabular),
                  ),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.isComplete ? 'ครบทุกหมวด พร้อมให้เจ้าหน้าที่ตรวจ' : 'บันทึกแล้ว ${g.completed} จาก 7 หมวด',
                          style: context.text.titleMedium,
                        ),
                        if (g.lastUpdated != null)
                          Text('ล่าสุด ${ThaiDate.withTime(g.lastUpdated!.toLocal())}', style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ).entrance(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
          SliverList.separated(
            itemCount: GapCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.md),
            itemBuilder: (context, i) {
              final c = GapCategory.values[i];
              return _CategorySection(
                category: c,
                progress: g,
                plotName: widget.plotName,
                onClear: widget.readOnly || !g.isDone(c) || c == GapCategory.traceability || _busy
                    ? null
                    : () => _clear(c),
              ).entrance(context, index: i + 1);
            },
          ),
        ],
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.progress, required this.plotName, this.onClear});

  final GapCategory category;
  final GapProgress progress;
  final String plotName;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = progress.isDone(category);
    final rows = <Widget>[];
    if (done && category == GapCategory.general) {
      for (final (k, v) in GapLabels.general(progress.general ?? const {}, plotName: plotName)) {
        rows.add(KeyValueRow(label: k, value: v));
      }
    } else if (done) {
      for (final (i, item) in progress.items(category).indexed) {
        if (item is! Map) continue;
        final e = GapLabels.entry(category, item, i);
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: p.brand, shape: BoxShape.circle),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: context.text.bodyMedium?.w600),
                      if ((e.subtitle ?? '').isNotEmpty && e.subtitle != '-')
                        Text(e.subtitle!, style: context.text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(icon: category.icon, tone: done ? Tone.brand : Tone.neutral, size: 36),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${category.code}  ${category.title}', style: context.text.titleSmall),
                    Text(GapLabels.summary(category, progress), style: context.text.bodySmall),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'ล้างข้อมูลหมวดนี้',
                  onPressed: onClear,
                  icon: Icon(AppIcons.broom, size: 20, color: p.inkSubtle),
                )
              else
                Icon(done ? AppIcons.checkCircleFill : AppIcons.pending, size: 20, color: done ? p.success : p.inkSubtle),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Divider(height: 1, color: p.line),
            const SizedBox(height: Space.sm),
            ...rows,
          ],
        ],
      ),
    );
  }
}
