import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/services/gap_service.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';

/// Lots issued for a plot, with the export flag and removal for staff.
class TraceabilityManagementSheet extends StatefulWidget {
  const TraceabilityManagementSheet({super.key, required this.plotId});

  final String plotId;

  @override
  State<TraceabilityManagementSheet> createState() => _TraceabilityManagementSheetState();
}

class _TraceabilityManagementSheetState extends State<TraceabilityManagementSheet> {
  List<Map<String, dynamic>> _lots = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

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
    try {
      final lots = await context.read<GapService>().getTraceabilityLots(widget.plotId);
      if (!mounted) return;
      setState(() {
        _lots = [for (final l in lots) if (l is Map) Map<String, dynamic>.from(l)];
        _loading = false;
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'โหลดล็อตไม่สำเร็จ';
      });
    }
  }

  Future<void> _toggleExported(Map<String, dynamic> lot) async {
    final id = '${lot['id']}';
    final next = lot['isExported'] != true;
    setState(() => _busy.add(id));
    try {
      await context.read<AdminService>().updateTraceability(id, {'isExported': next});
      if (!mounted) return;
      setState(() => lot['isExported'] = next);
      GapService.invalidate(widget.plotId);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _delete(Map<String, dynamic> lot) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ลบล็อต ${lot['lotNumber'] ?? ''}?',
      message: 'QR ของล็อตนี้จะใช้ตรวจสอบย้อนกลับไม่ได้อีก',
      confirmLabel: 'ลบล็อต',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final id = '${lot['id']}';
    setState(() => _busy.add(id));
    try {
      await context.read<AdminService>().deleteTraceability(id);
      if (!mounted) return;
      GapService.invalidate(widget.plotId);
      setState(() => _lots.remove(lot));
      AppToast.success(context, 'ลบล็อตแล้ว');
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = Space.xl + MediaQuery.paddingOf(context).bottom;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, bottom),
        child: const SkeletonList(count: 3, thumbnail: false),
      );
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, bottom),
        child: ErrorState(message: _error, onRetry: _load, compact: true),
      );
    }
    if (_lots.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, bottom),
        child: const EmptyState(
          title: 'ยังไม่มีล็อตผลผลิต',
          message: 'ล็อตจะถูกสร้างเมื่อเกษตรกรบันทึกการเก็บเกี่ยวและออกเลขล็อต',
          compact: true,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, bottom),
      itemCount: _lots.length,
      separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
      itemBuilder: (context, i) {
        final lot = _lots[i];
        final id = '${lot['id']}';
        final exported = lot['isExported'] == true;
        final busy = _busy.contains(id);
        final created = DateTime.tryParse('${lot['harvestDate'] ?? lot['createdAt'] ?? ''}');
        final amount = lot['quantity'] ?? lot['yieldAmount'];

        return AppCard(
          padding: const EdgeInsets.fromLTRB(Space.md + 2, Space.md, Space.xs, Space.md),
          child: Row(
            children: [
              IconTile(icon: AppIcons.qr, tone: exported ? Tone.success : Tone.brand, size: 40),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${lot['lotNumber'] ?? id}', style: context.text.titleSmall?.mono),
                    Text(
                      [
                        if (created != null) ThaiDate.short(created.toLocal()),
                        if (amount != null) '$amount ${lot['unit'] ?? 'กก.'}',
                      ].join(' · '),
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: Space.xs),
                    StatusBadge(
                      label: exported ? 'ส่งออกแล้ว' : 'ยังไม่ส่งออก',
                      tone: exported ? Tone.success : Tone.neutral,
                    ),
                  ],
                ),
              ),
              if (busy)
                Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: p.brand),
                  ),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'ตัวเลือก',
                  icon: Icon(AppIcons.more, color: p.inkSubtle),
                  onSelected: (v) => v == 'delete' ? _delete(lot) : _toggleExported(lot),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Text(exported ? 'ทำเครื่องหมายว่ายังไม่ส่งออก' : 'ทำเครื่องหมายว่าส่งออกแล้ว'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('ลบล็อต', style: TextStyle(color: p.danger)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
