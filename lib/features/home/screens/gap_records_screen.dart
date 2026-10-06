import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/gap_service.dart';
import '../../../core/services/plot_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../../gap/gap_categories.dart';
import '../../gap/screens/gap_main_screen.dart';
import '../../map/screens/map_drawing_screen.dart';

/// Records tab: GAP progress for every plot, with the next category to fill.
class GapRecordsScreen extends StatefulWidget {
  const GapRecordsScreen({super.key});

  @override
  State<GapRecordsScreen> createState() => _GapRecordsScreenState();
}

class _GapRecordsScreenState extends State<GapRecordsScreen> {
  List<PlotModel>? _plots;
  Object? _error;
  int _reloadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final plots = await context.read<PlotService>().getMyPlots();
      if (mounted) {
        setState(() {
          _plots = plots;
          _reloadToken++;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plots = _plots;
    return PageScaffold(
      title: 'บันทึก GAP',
      subtitle: 'ความคืบหน้า 7 หมวดของแต่ละแปลง',
      showBack: false,
      onRefresh: _load,
      bottomPadding: 120,
      slivers: [
        if (plots == null && _error == null)
          const SliverToBoxAdapter(child: SkeletonList(count: 3))
        else if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(onRetry: _load)))
        else if (plots!.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: 'ยังไม่มีแปลงให้บันทึก',
                message: 'เริ่มจากวาดขอบเขตแปลงบนแผนที่ แล้วกลับมาบันทึก GAP ทีละหมวด',
                mood: MascotMood.happy,
                actionLabel: 'วาดแปลงใหม่',
                onAction: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MapDrawingScreen()),
                  );
                  _load();
                },
              ),
            ),
          )
        else ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: Space.lg),
              child: InlineBanner(
                tone: Tone.info,
                message:
                    'บันทึกให้ครบทั้ง 7 หมวดก่อนยื่นตรวจประเมิน แปลงที่อนุมัติแล้วจะเปิดดูได้อย่างเดียว',
              ),
            ),
          ),
          SliverList.separated(
            itemCount: plots.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.md),
            itemBuilder: (context, i) => _GapPlotCard(
              key: ValueKey('${plots[i].id}-$_reloadToken'),
              plot: plots[i],
              index: i,
            ).entrance(context, index: i),
          ),
        ],
      ],
    );
  }
}

class _GapPlotCard extends StatefulWidget {
  const _GapPlotCard({super.key, required this.plot, required this.index});

  final PlotModel plot;
  final int index;

  @override
  State<_GapPlotCard> createState() => _GapPlotCardState();
}

class _GapPlotCardState extends State<_GapPlotCard> {
  GapProgress? _progress;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Stagger loads so many plots do not hit the API at the same moment.
    Future.delayed(Duration(milliseconds: 220 * widget.index), _load);
  }

  Future<void> _load({bool force = false}) async {
    final id = widget.plot.id;
    if (id == null) return;
    try {
      final progress = await context.read<GapService>().getProgress(id, force: force);
      if (mounted) {
        setState(() {
          _progress = progress;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open() async {
    final approved = widget.plot.status == 'APPROVED';
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GapMainScreen(
          plotId: widget.plot.id ?? '',
          plotName: widget.plot.name,
          isReadOnly: approved,
        ),
      ),
    );
    _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = _progress;
    final (label, tone) = StatusLabels.plot(widget.plot.status);
    final approved = widget.plot.status == 'APPROVED';

    return AppCard(
      onTap: _open,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlotShape(points: widget.plot.boundary, size: 48, showGrid: false),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    Text(
                      progress?.lastUpdated == null
                          ? (widget.plot.species ?? 'ยังไม่มีบันทึก')
                          : 'บันทึกล่าสุด ${ThaiDate.relative(progress!.lastUpdated)}',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: Space.lg),
          if (progress == null && !_failed)
            const Shimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 6, radius: 6),
                  SizedBox(height: Space.md),
                  SkeletonBox(width: 220, height: 24, radius: Radii.pill),
                ],
              ),
            )
          else if (_failed)
            Row(
              children: [
                Icon(AppIcons.warningCircle, size: 18, color: p.warning),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text('โหลดความคืบหน้าไม่สำเร็จ', style: context.text.bodySmall),
                ),
                TextButton(onPressed: () => _load(force: true), child: const Text('ลองใหม่')),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(child: ProgressBar(value: progress!.ratio)),
                const SizedBox(width: Space.md),
                Text(
                  '${progress.completed}/7 หมวด',
                  style: context.text.labelMedium?.copyWith(color: p.ink).tabular,
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in GapCategory.values)
                  _CategoryDot(category: c, done: progress.isDone(c)),
              ],
            ),
            const SizedBox(height: Space.md),
            Divider(height: 1, color: p.line),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Icon(
                  approved
                      ? AppIcons.gap
                      : progress.isComplete
                          ? AppIcons.checkCircle
                          : AppIcons.forward,
                  size: 18,
                  color: approved || progress.isComplete ? p.success : p.brand,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    approved
                        ? 'ผ่านการรับรอง GAP แล้ว'
                        : progress.isComplete
                            ? 'บันทึกครบทุกหมวด พร้อมยื่นตรวจ'
                            : 'ถัดไป: ${progress.next!.code} ${progress.next!.title}',
                    style: context.text.labelLarge?.copyWith(
                      fontSize: 14,
                      color: approved || progress.isComplete ? p.success : p.brand,
                    ),
                  ),
                ),
                Icon(AppIcons.chevronRight, size: 18, color: p.inkSubtle),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.category, required this.done});

  final GapCategory category;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: '${category.code} ${category.title}',
      child: AnimatedContainer(
        duration: Motion.base,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: done ? p.brandSoft : p.surface,
          borderRadius: Radii.chip,
          border: Border.all(color: done ? Colors.transparent : p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (done) ...[
              Icon(AppIcons.check, size: 11, color: p.brandStrong),
              const SizedBox(width: 3),
            ],
            Text(
              category.code,
              style: context.text.labelMedium?.copyWith(
                color: done ? p.brandStrong : p.inkSubtle,
                fontWeight: FontWeight.w600,
              ).tabular,
            ),
          ],
        ),
      ),
    );
  }
}
