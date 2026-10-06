import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/audit_log_model.dart';

/// Who did what, and when. The server scopes the trail by role: officers see
/// their own actions, super admins see everyone's.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  static const _pageSize = 20;

  final _service = AuditService();
  final List<AuditLog> _logs = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _type;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await _service.getAuditLogs(page: 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _logs
          ..clear()
          ..addAll(logs);
        _page = 1;
        _hasMore = logs.length >= _pageSize;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'โหลดบันทึกไม่สำเร็จ';
      });
    }
  }

  Future<void> _more() async {
    setState(() => _loadingMore = true);
    try {
      final logs = await _service.getAuditLogs(page: _page + 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _logs.addAll(logs);
        _page++;
        _hasMore = logs.length >= _pageSize;
      });
    } on Object catch (_) {
      if (mounted) AppToast.error(context, 'โหลดเพิ่มไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  static (String, IconData, Tone) describe(String action) {
    final a = action.toUpperCase();
    final tone = a.startsWith('APPROVE')
        ? Tone.success
        : a.startsWith('REJECT') || a.startsWith('DELETE')
            ? Tone.danger
            : a.startsWith('CREATE')
                ? Tone.brand
                : Tone.info;
    final label = switch (a) {
      'APPROVE_PLOT' => 'อนุมัติแปลง',
      'REJECT_PLOT' => 'ไม่อนุมัติแปลง',
      'UPDATE_PLOT' => 'แก้ไขแปลง',
      'CREATE_PLOT' => 'สร้างแปลง',
      'APPROVE_USER' => 'อนุมัติสมาชิก',
      'REJECT_USER' => 'ไม่อนุมัติสมาชิก',
      'DELETE_USER' => 'ลบบัญชี',
      'RESTORE_USER' => 'กู้คืนบัญชี',
      'UPDATE_ROLE' || 'CHANGE_ROLE' => 'เปลี่ยนสิทธิ์',
      'CREATE_ADMIN' => 'เพิ่มเจ้าหน้าที่',
      'DELETE_ADMIN' => 'ลบเจ้าหน้าที่',
      'ASSIGN_USERS' || 'REASSIGN_USER' => 'มอบหมายสมาชิก',
      'GAP_FEEDBACK' => 'คำแนะนำ GAP',
      'UPDATE_TRACEABILITY' => 'แก้ไขล็อต',
      'LOGIN' => 'เข้าสู่ระบบ',
      _ => a.replaceAll('_', ' ').toLowerCase(),
    };
    final icon = switch (a.split('_').last) {
      'PLOT' => AppIcons.plot,
      'USER' || 'USERS' || 'ROLE' => AppIcons.user,
      'ADMIN' => AppIcons.officer,
      'FEEDBACK' => AppIcons.gap,
      'TRACEABILITY' => AppIcons.lot,
      'LOGIN' => AppIcons.lock,
      _ => AppIcons.history,
    };
    return (label, icon, tone);
  }

  String _groupOf(DateTime? date) {
    if (date == null) return 'ไม่ระบุวันที่';
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return 'วันนี้';
    if (diff == 1) return 'เมื่อวาน';
    return ThaiDate.long(date);
  }

  @override
  Widget build(BuildContext context) {
    final types = {for (final l in _logs) if (l.resourceType != null) l.resourceType!};
    final visible = _type == null ? _logs : _logs.where((l) => l.resourceType == _type).toList();
    final groups = <String, List<AuditLog>>{};
    for (final l in visible) {
      groups.putIfAbsent(_groupOf(l.createdAt), () => []).add(l);
    }

    String typeLabel(String t) => switch (t) {
          'PLOT' => 'แปลง',
          'USER' => 'บัญชี',
          'GAP' => 'GAP',
          'TRACEABILITY' => 'ล็อต',
          _ => t,
        };

    return PageScaffold(
      title: 'บันทึกการทำงาน',
      subtitle: 'การอนุมัติ การแก้ไข และการจัดการบัญชี',
      onRefresh: _reload,
      slivers: [
        if (types.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Space.lg),
              child: FilterChips<String?>(
                value: _type,
                onChanged: (v) => setState(() => _type = v),
                options: [
                  (null, 'ทั้งหมด', _logs.length),
                  for (final t in types)
                    (t, typeLabel(t), _logs.where((l) => l.resourceType == t).length),
                ],
              ),
            ),
          ),
        if (_loading)
          const SliverToBoxAdapter(child: SkeletonList(count: 6, thumbnail: false))
        else if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _reload)))
        else if (visible.isEmpty)
          const SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: 'ยังไม่มีบันทึก',
                message: 'การอนุมัติและการแก้ไขข้อมูลจะถูกบันทึกไว้ที่นี่โดยอัตโนมัติ',
              ),
            ),
          )
        else ...[
          for (final entry in groups.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Space.sm, left: 4),
                child: Text(entry.key, style: context.text.labelMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Column(
                  children: [
                    for (final (i, log) in entry.value.indexed)
                      _LogRow(log: log, last: i == entry.value.length - 1),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.lg)),
          ],
          if (_hasMore && _type == null)
            SliverToBoxAdapter(
              child: Center(
                child: AppButton.ghost(
                  label: 'โหลดรายการก่อนหน้า',
                  loading: _loadingMore,
                  onPressed: _more,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log, required this.last});

  final AuditLog log;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, icon, tone) = _AuditLogScreenState.describe(log.action);
    final time = log.createdAt == null
        ? ''
        : '${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                const SizedBox(height: Space.md),
                IconTile(icon: icon, tone: tone, size: 32),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.only(top: 4),
                      color: p.line,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, Space.md, Space.lg, Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label, style: context.text.titleSmall)),
                      Text(time, style: context.text.labelSmall?.tabular),
                    ],
                  ),
                  if (log.details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(log.details, style: context.text.bodySmall),
                  ],
                  if (log.actorName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'โดย ${log.actorName}',
                      style: context.text.labelSmall?.copyWith(color: p.inkSubtle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
