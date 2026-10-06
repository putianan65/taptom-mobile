import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/services/super_admin_service.dart';
import '../../../core/widgets/widgets.dart';

/// Super admin list of field officers, with their territory and how many
/// members each one looks after.
class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final raw = await context.read<SuperAdminService>().getAdminList();
      if (!mounted) return;
      setState(() {
        _admins = [for (final a in raw) if (a is Map) Map<String, dynamic>.from(a)];
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _delete(Map<String, dynamic> admin) async {
    final name = officerName(admin);
    final ok = await AppDialogs.confirm(
      context,
      title: 'ลบบัญชีเจ้าหน้าที่ $name?',
      message: 'สมาชิกในความดูแลจะไม่มีผู้รับผิดชอบจนกว่าจะมอบหมายใหม่',
      confirmLabel: 'ลบบัญชี',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<SuperAdminService>().deleteAdmin('${admin['id']}');
      if (!mounted) return;
      AppToast.success(context, 'ลบบัญชี $name แล้ว');
      _load();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _create() async {
    await context.push(Routes.superAdminCreate);
    if (mounted) _load();
  }

  Future<void> _open(Map<String, dynamic> admin) async {
    await context.push(Routes.superAdminDetail, extra: admin);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final admins = q.isEmpty
        ? _admins
        : _admins
            .where((a) => '${officerName(a)} ${a['phone']} ${officerScope(a)}'.toLowerCase().contains(q))
            .toList();
    final members = _admins.fold<int>(0, (sum, a) => sum + managedCount(a));

    return PageScaffold(
      title: 'เจ้าหน้าที่',
      subtitle: _loading ? null : '${_admins.length} คน ดูแลสมาชิกรวม $members คน',
      showBack: !widget.isEmbedded,
      onRefresh: _load,
      bottomPadding: widget.isEmbedded && context.isCompact ? 96 : Space.x4,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: Space.sm),
          child: AppButton.tonal(
            label: 'เพิ่ม',
            icon: AppIcons.userAdd,
            size: ButtonSize.compact,
            onPressed: _create,
          ),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: AppSearchField(
              hint: 'ชื่อ เบอร์โทร หรือพื้นที่',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
        if (_loading && _admins.isEmpty)
          const SliverToBoxAdapter(child: SkeletonList(count: 4))
        else if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else if (admins.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: q.isEmpty ? 'ยังไม่มีเจ้าหน้าที่' : 'ไม่พบเจ้าหน้าที่ที่ค้นหา',
                message: q.isEmpty ? 'เพิ่มเจ้าหน้าที่และกำหนดพื้นที่ดูแลได้จากปุ่มเพิ่ม' : null,
                actionLabel: q.isEmpty ? 'เพิ่มเจ้าหน้าที่' : null,
                onAction: q.isEmpty ? _create : null,
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: admins.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) => _OfficerTile(
              admin: admins[i],
              onTap: () => _open(admins[i]),
              onDelete: () => _delete(admins[i]),
            ).entrance(context, index: i),
          ),
      ],
    );
  }
}

String officerName(Map<String, dynamic> a) {
  final name = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim();
  return name.isEmpty ? 'ไม่ระบุชื่อ' : name;
}

String officerScope(Map<String, dynamic> a) {
  String? v(String k) {
    final s = a[k]?.toString();
    return s == null || s.isEmpty ? null : s;
  }

  final parts = [
    if (v('subDistrict') ?? v('subdistrict') case final s?) 'ต.$s',
    if (v('district') case final s?) 'อ.$s',
    if (v('province') case final s?) 'จ.$s',
  ];
  if (parts.isNotEmpty) return parts.join(' ');
  return v('region') ?? 'ยังไม่กำหนดพื้นที่';
}

int managedCount(Map<String, dynamic> a) {
  final n = a['managedUsersCount'];
  if (n is num) return n.toInt();
  final list = a['managedUsers'];
  return list is List ? list.length : 0;
}

class _OfficerTile extends StatelessWidget {
  const _OfficerTile({required this.admin, required this.onTap, required this.onDelete});

  final Map<String, dynamic> admin;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final count = managedCount(admin);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(Space.md + 2, Space.md + 2, Space.xs, Space.md + 2),
      child: Row(
        children: [
          InitialsAvatar(name: officerName(admin)),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(officerName(admin), style: context.text.titleSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(AppIcons.pin, size: 14, color: p.inkSubtle),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        officerScope(admin),
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count', style: context.text.titleMedium?.tabular),
              Text('สมาชิก', style: context.text.labelSmall),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'ตัวเลือก',
            icon: Icon(AppIcons.more, color: p.inkSubtle),
            onSelected: (v) => v == 'delete' ? onDelete() : onTap(),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'open', child: Text('ดูรายละเอียด')),
              PopupMenuItem(
                value: 'delete',
                child: Text('ลบบัญชี', style: TextStyle(color: p.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
