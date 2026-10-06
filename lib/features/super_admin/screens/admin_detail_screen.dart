import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/super_admin_service.dart';
import '../../../core/widgets/widgets.dart';
import 'admin_management_screen.dart' show managedCount, officerName, officerScope;

/// One officer: territory, the members they look after, and tools to assign
/// unassigned members or move a member to another officer.
class AdminDetailScreen extends StatefulWidget {
  const AdminDetailScreen({super.key, required this.admin});

  final Map<String, dynamic> admin;

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  late Map<String, dynamic> _admin = widget.admin;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _managed = [];
  bool _loading = true;
  bool _busy = false;

  String get _id => '${_admin['id'] ?? ''}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String? _managerOf(Map<String, dynamic> u) =>
      (u['managedByAdminId'] ?? u['adminId'])?.toString();

  static List<Map<String, dynamic>> _maps(List<dynamic> raw) =>
      [for (final e in raw) if (e is Map) Map<String, dynamic>.from(e)];

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = context.read<SuperAdminService>();
    try {
      final admins = _maps(await service.getAdminList());
      final me = admins.where((a) => '${a['id']}' == _id).firstOrNull ?? _admin;
      var users = <Map<String, dynamic>>[];
      try {
        users = _maps(await service.getUsers());
      } on Object catch (e) {
        debugPrint('User list unavailable: $e');
      }

      // Prefer the authoritative list on the admin record; fall back to the
      // manager field on each user.
      final fromAdmin = me['managedUsers'] is List ? _maps(me['managedUsers'] as List) : <Map<String, dynamic>>[];
      final fromUsers = users.where((u) => _managerOf(u) == _id).toList();

      if (!mounted) return;
      setState(() {
        _admin = me;
        _admins = admins;
        _users = users;
        _managed = fromUsers.length >= fromAdmin.length ? fromUsers : fromAdmin;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Set<String> get _assignedIds => {
        for (final a in _admins)
          if (a['managedUsers'] is List)
            for (final u in a['managedUsers'] as List)
              if (u is Map) '${u['id']}',
        for (final u in _users)
          if (_managerOf(u) != null) '${u['id']}',
      };

  Future<void> _assign() async {
    final assigned = _assignedIds;
    final candidates = _users.where((u) {
      final role = '${u['role'] ?? ''}'.toUpperCase();
      return !assigned.contains('${u['id']}') && (role == 'USER' || role == 'FARMER');
    }).toList();

    final ids = await showAppSheet<List<String>>(
      context,
      title: 'มอบหมายสมาชิก',
      subtitle: 'ให้ ${officerName(_admin)} ดูแล',
      expand: true,
      child: _AssignPicker(users: candidates),
    );
    if (ids == null || ids.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<SuperAdminService>().assignUsersToAdmin(_id, ids);
      if (!mounted) return;
      AppToast.success(context, 'มอบหมาย ${ids.length} คนแล้ว');
      await _load();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(Map<String, dynamic> user) async {
    final others = _admins.where((a) => '${a['id']}' != _id).toList();
    if (others.isEmpty) {
      AppToast.info(context, 'ยังไม่มีเจ้าหน้าที่คนอื่นในระบบ');
      return;
    }
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final target = await showAppSheet<String>(
      context,
      title: 'ย้ายสมาชิก',
      subtitle: name,
      expand: true,
      child: _OfficerChoice(admins: others),
    );
    if (target == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<SuperAdminService>().reassignUser(userId: '${user['id']}', newAdminId: target);
      if (!mounted) return;
      AppToast.success(context, 'ย้าย $name แล้ว');
      await _load();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final count = _loading ? managedCount(_admin) : _managed.length;

    return PageScaffold(
      title: officerName(_admin),
      subtitle: 'เจ้าหน้าที่ภาคสนาม',
      onRefresh: _load,
      slivers: [
        SliverToBoxAdapter(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    InitialsAvatar(name: officerName(_admin), size: 56),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$count', style: context.text.displaySmall?.tabular.copyWith(color: p.brand)),
                          Text('สมาชิกในความดูแล', style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                KeyValueRow(label: 'เบอร์โทร', value: '${_admin['phone'] ?? '-'}', mono: true),
                KeyValueRow(label: 'พื้นที่ดูแล', value: officerScope(_admin)),
                if ((_admin['region'] ?? '').toString().isNotEmpty)
                  KeyValueRow(label: 'ภูมิภาค', value: '${_admin['region']}'),
              ],
            ),
          ).entrance(context),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.sm),
            child: Row(
              children: [
                const Expanded(child: SectionHeader(title: 'สมาชิกในความดูแล')),
                AppButton.tonal(
                  label: 'มอบหมาย',
                  icon: AppIcons.userAdd,
                  size: ButtonSize.compact,
                  loading: _busy,
                  onPressed: _loading ? null : _assign,
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: SkeletonList(count: 3, thumbnail: false))
        else if (_managed.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: 'ยังไม่มีสมาชิกในความดูแล',
                message: 'กดมอบหมายเพื่อเลือกสมาชิกที่ยังไม่มีเจ้าหน้าที่ดูแล',
                actionLabel: 'มอบหมายสมาชิก',
                onAction: _assign,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: ListGroup(
              children: [
                for (final u in _managed)
                  ListRow(
                    leading: InitialsAvatar(
                      name: '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim().ifEmpty('?'),
                      size: 36,
                    ),
                    title: '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim().ifEmpty('ไม่ระบุชื่อ'),
                    subtitle: '${u['phone'] ?? ''}',
                    showChevron: false,
                    trailing: IconButton(
                      tooltip: 'ย้ายไปให้เจ้าหน้าที่คนอื่น',
                      onPressed: _busy ? null : () => _move(u),
                      icon: Icon(AppIcons.userSwitch, color: p.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _AssignPicker extends StatefulWidget {
  const _AssignPicker({required this.users});

  final List<Map<String, dynamic>> users;

  @override
  State<_AssignPicker> createState() => _AssignPickerState();
}

class _AssignPickerState extends State<_AssignPicker> {
  final Set<String> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = _query.trim().toLowerCase();
    final users = q.isEmpty
        ? widget.users
        : widget.users
            .where((u) => '${u['firstName']} ${u['lastName']} ${u['phone']} ${u['district']}'.toLowerCase().contains(q))
            .toList();

    if (widget.users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.x3),
        child: EmptyState(
          title: 'สมาชิกทุกคนมีผู้ดูแลแล้ว',
          message: 'ใช้ปุ่มย้ายในรายชื่อเพื่อเปลี่ยนผู้ดูแลแทน',
          mood: MascotMood.joy,
          compact: true,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.md),
          child: AppSearchField(
            hint: 'ค้นหาสมาชิก',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              final id = '${u['id']}';
              final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
              final selected = _selected.contains(id);
              return CheckboxListTile(
                value: selected,
                onChanged: (v) => setState(() => v == true ? _selected.add(id) : _selected.remove(id)),
                activeColor: p.brand,
                controlAffinity: ListTileControlAffinity.trailing,
                shape: const RoundedRectangleBorder(borderRadius: Radii.control),
                secondary: InitialsAvatar(name: name.isEmpty ? '?' : name, size: 36),
                title: Text(name.isEmpty ? 'ไม่ระบุชื่อ' : name, style: context.text.titleSmall),
                subtitle: Text(
                  [u['phone'], if (u['district'] != null) 'อ.${u['district']}'].join(' · '),
                  style: context.text.bodySmall?.tabular,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Space.xl,
            Space.md,
            Space.xl,
            Space.lg + MediaQuery.paddingOf(context).bottom,
          ),
          child: AppButton(
            label: _selected.isEmpty ? 'เลือกสมาชิก' : 'มอบหมาย ${_selected.length} คน',
            expand: true,
            onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
          ),
        ),
      ],
    );
  }
}

class _OfficerChoice extends StatelessWidget {
  const _OfficerChoice({required this.admins});

  final List<Map<String, dynamic>> admins;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: admins.length,
      separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
      itemBuilder: (context, i) {
        final a = admins[i];
        return AppCard(
          padding: const EdgeInsets.all(Space.md),
          onTap: () => Navigator.of(context).pop('${a['id']}'),
          child: Row(
            children: [
              InitialsAvatar(name: officerName(a), size: 40),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(officerName(a), style: context.text.titleSmall),
                    Text(officerScope(a), style: context.text.bodySmall),
                  ],
                ),
              ),
              Text('${managedCount(a)} คน', style: context.text.labelMedium?.tabular),
            ],
          ),
        );
      },
    );
  }
}
