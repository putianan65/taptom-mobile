import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/database_helper.dart';
import '../../../core/services/gap_service.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/gap_draft_model.dart';
import '../gap_categories.dart';
import 'forms/gap_general_form.dart';
import 'forms/gap_harvest_form.dart';
import 'forms/gap_inputs_form.dart';
import 'forms/gap_management_form.dart';
import 'forms/gap_post_harvest_form.dart';
import 'forms/gap_safety_form.dart';
import 'forms/gap_traceability_form.dart';
import 'gap_summary_screen.dart';
import 'plot_gallery_screen.dart';

/// GAP hub for one plot: overall progress, the seven categories and any
/// unsent drafts saved on this device.
class GapMainScreen extends StatefulWidget {
  const GapMainScreen({
    super.key,
    required this.plotId,
    this.plotName,
    this.isReadOnly = false,
  });

  final String plotId;
  final String? plotName;
  final bool isReadOnly;

  @override
  State<GapMainScreen> createState() => _GapMainScreenState();
}

class _GapMainScreenState extends State<GapMainScreen> {
  GapProgress? _progress;
  List<GapDraftModel> _drafts = [];
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _failed = false);
    try {
      final results = await Future.wait([
        context.read<GapService>().getProgress(widget.plotId, force: force),
        DatabaseHelper.instance
            .getDraftsForPlot(widget.plotId)
            .catchError((_) => <GapDraftModel>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _progress = results[0] as GapProgress;
        _drafts = results[1] as List<GapDraftModel>;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Widget _formFor(GapCategory category) {
    final progress = _progress ?? GapProgress.empty;
    Map<String, dynamic>? first(List<dynamic> list) =>
        list.isNotEmpty && list.first is Map
            ? Map<String, dynamic>.from(list.first as Map)
            : null;
    final id = widget.plotId;
    return switch (category) {
      GapCategory.general => GapGeneralForm(plotId: id),
      GapCategory.inputs => GapInputsForm(
          plotId: id,
          existingId: first(progress.inputs)?['id']?.toString(),
          existingData: first(progress.inputs),
        ),
      GapCategory.management => GapManagementForm(
          plotId: id,
          existingId: first(progress.activities)?['id']?.toString(),
          existingData: first(progress.activities),
        ),
      GapCategory.harvest => GapHarvestForm(
          plotId: id,
          existingId: first(progress.harvests)?['id']?.toString(),
          existingData: first(progress.harvests),
        ),
      GapCategory.postHarvest => GapPostHarvestForm(
          plotId: id,
          existingId: first(progress.postHarvests)?['id']?.toString(),
          existingData: first(progress.postHarvests),
        ),
      GapCategory.safety => GapSafetyForm(
          plotId: id,
          existingId: first(progress.trainings)?['id']?.toString(),
          existingData: first(progress.trainings),
        ),
      GapCategory.traceability => GapTraceabilityForm(
          plotId: id,
          isReadOnly: widget.isReadOnly,
        ),
    };
  }

  Future<void> _open(GapCategory category) async {
    if (widget.isReadOnly && category != GapCategory.traceability) {
      AppToast.show(
        context,
        'แปลงที่รับรองแล้วเปิดดูได้อย่างเดียว ดูรายละเอียดได้ที่สรุปข้อมูล',
        tone: Tone.warning,
      );
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _formFor(category)),
    );
    GapService.invalidate(widget.plotId);
    if (mounted) _load(force: true);
  }

  GapCategory? _categoryOfDraft(GapDraftModel draft) {
    final key = draft.category.replaceFirst(RegExp('_${RegExp.escape(widget.plotId)}\$'), '');
    return switch (key) {
      'general' => GapCategory.general,
      'inputs' => GapCategory.inputs,
      'management' => GapCategory.management,
      'harvest' => GapCategory.harvest,
      'post_harvest' => GapCategory.postHarvest,
      'safety' => GapCategory.safety,
      _ => null,
    };
  }

  Future<void> _deleteDraft(GapDraftModel draft) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ลบฉบับร่าง',
      message: 'ข้อมูลที่ยังไม่ได้ส่งในฉบับร่างนี้จะหายไป',
      confirmLabel: 'ลบ',
      destructive: true,
    );
    if (!ok) return;
    await DatabaseHelper.instance.deleteDraft(draft.category);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = _progress;

    return PageScaffold(
      title: widget.isReadOnly ? 'ข้อมูล GAP' : 'บันทึก GAP',
      subtitle: widget.plotName,
      onRefresh: () => _load(force: true),
      actions: [
        AppIconButton(
          icon: AppIcons.gallery,
          tooltip: 'รูปภาพแปลง',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlotGalleryScreen(
                plotId: widget.plotId,
                plotName: widget.plotName,
              ),
            ),
          ),
        ),
        const SizedBox(width: Space.sm),
        AppIconButton(
          icon: AppIcons.checklist,
          tooltip: 'สรุปข้อมูล',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GapSummaryScreen(
                plotId: widget.plotId,
                plotName: widget.plotName ?? 'แปลง',
              ),
            ),
          ),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: _failed
              ? AppCard(child: ErrorState(onRetry: () => _load(force: true)))
              : _Overview(progress: progress, readOnly: widget.isReadOnly)
                  .entrance(context),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'หมวดการบันทึก', subtitle: 'แตะเพื่อเพิ่มหรือแก้ไขข้อมูล'),
        ),
        SliverList.separated(
          itemCount: GapCategory.values.length,
          separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
          itemBuilder: (context, i) {
            final c = GapCategory.values[i];
            return _CategoryRow(
              category: c,
              loading: progress == null && !_failed,
              done: progress?.isDone(c) ?? false,
              count: progress?.count(c) ?? 0,
              isNext: progress?.next == c && !widget.isReadOnly,
              locked: widget.isReadOnly && c != GapCategory.traceability,
              onTap: () => _open(c),
            ).entrance(context, index: i + 1);
          },
        ),
        if (!widget.isReadOnly && _drafts.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'ฉบับร่างในเครื่อง',
              subtitle: 'ยังไม่ได้ส่งขึ้นระบบ',
            ),
          ),
          SliverToBoxAdapter(
            child: ListGroup(
              children: [
                for (final d in _drafts)
                  ListRow(
                    icon: AppIcons.draft,
                    tone: Tone.warning,
                    title: _categoryOfDraft(d)?.title ?? d.category,
                    subtitle: 'แก้ไขล่าสุด ${ThaiDate.relative(DateTime.tryParse(d.lastUpdated))}',
                    onTap: _categoryOfDraft(d) == null ? null : () => _open(_categoryOfDraft(d)!),
                    trailing: IconButton(
                      tooltip: 'ลบฉบับร่าง',
                      onPressed: () => _deleteDraft(d),
                      icon: Icon(AppIcons.delete, size: 20, color: p.inkSubtle),
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
  const _Overview({required this.progress, required this.readOnly});

  final GapProgress? progress;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pr = progress;
    final String title;
    final String message;
    if (pr == null) {
      title = 'กำลังตรวจความคืบหน้า';
      message = 'รวบรวมข้อมูลจากทั้ง 7 หมวด';
    } else if (readOnly) {
      title = 'ผ่านการรับรองแล้ว';
      message = 'ข้อมูลถูกล็อกไว้ตามผลการตรวจประเมิน ดูย้อนหลังได้ทุกหมวด';
    } else if (pr.isComplete) {
      title = 'บันทึกครบทุกหมวดแล้ว';
      message = 'ตรวจทานความถูกต้องในหน้าสรุป แล้วรอเจ้าหน้าที่ตรวจประเมิน';
    } else {
      title = 'บันทึกแล้ว ${pr.completed} จาก 7 หมวด';
      message = 'ขั้นต่อไป: ${pr.next!.code} ${pr.next!.title}';
    }

    return AppCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Row(
        children: [
          ProgressRing(
            value: pr?.ratio ?? 0,
            size: 84,
            stroke: 8,
            color: readOnly || (pr?.isComplete ?? false) ? p.success : p.brand,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${pr?.completed ?? 0}',
                  style: context.text.headlineSmall?.copyWith(
                    fontFamily: AppFonts.text,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ).tabular,
                ),
                Text('จาก 7', style: context.text.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: Space.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(message, style: context.text.bodySmall),
                if (pr?.lastUpdated != null) ...[
                  const SizedBox(height: Space.sm),
                  Text(
                    'อัปเดต ${ThaiDate.withTime(pr!.lastUpdated)}',
                    style: context.text.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.loading,
    required this.done,
    required this.count,
    required this.isNext,
    required this.locked,
    required this.onTap,
  });

  final GapCategory category;
  final bool loading;
  final bool done;
  final int count;
  final bool isNext;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md + 2),
      borderColor: isNext ? p.brand.withValues(alpha: 0.5) : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? p.brandSoft : p.surfaceSunken,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(category.icon, size: 21, color: done ? p.brand : p.inkMuted),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category.code,
                      style: context.text.labelMedium?.copyWith(
                        color: p.inkSubtle,
                        fontWeight: FontWeight.w600,
                      ).tabular,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        category.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                    ),
                  ],
                ),
                Text(
                  category.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          if (loading)
            const Shimmer(child: SkeletonBox(width: 56, height: 22, radius: Radii.pill))
          else if (locked)
            Icon(AppIcons.lock, size: 18, color: p.inkSubtle)
          else if (done)
            StatusBadge(
              label: count > 1 ? '$count รายการ' : 'บันทึกแล้ว',
              tone: Tone.success,
            )
          else if (isNext)
            const StatusBadge(label: 'ทำต่อ', tone: Tone.brand, icon: AppIcons.forward)
          else
            const StatusBadge(label: 'ยังไม่บันทึก', dot: false),
        ],
      ),
    );
  }
}
