import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/super_admin_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../home/screens/admin_dashboard_screen.dart' show staffScope;
import '../providers/admin_state_provider.dart';
import 'admin_plot_list_screen.dart';

enum _Filter { all, pending, approved, rejected, deleted }

/// Members in scope. Admins review applications from their territory;
/// super admins see every account and can also change roles, move members
/// between officers, and delete or restore accounts.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({
    super.key,
    this.isEmbedded = false,
    this.onUserSelected,
    this.initialStatus,
  });

  /// True when shown as a tab in the staff shell.
  final bool isEmbedded;

  /// Opens on the pending filter when 'PENDING'.
  final String? initialStatus;

  /// Overrides the default detail sheet, e.g. when picking a member.
  final ValueChanged<UserModel>? onUserSelected;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late _Filter _filter =
      widget.initialStatus == 'PENDING' ? _Filter.pending : _Filter.all;
  String _query = '';
  final Set<String> _busy = {};

  bool get _isSuperAdmin =>
      context.read<AuthProvider>().currentUser?.role == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final provider = context.read<AdminStateProvider>();
    await provider.loadUsers();
    if (mounted && _isSuperAdmin) await provider.loadDeletedUsers();
  }

  List<UserModel> _source(AdminStateProvider s) => switch (_filter) {
        _Filter.all => s.allUsers,
        _Filter.pending => s.pendingUsers,
        _Filter.approved => s.approvedUsers,
        _Filter.rejected =>
          s.allUsers.where((u) => u.membershipStatus == MembershipStatus.rejected).toList(),
        _Filter.deleted => s.deletedUsers,
      };

  List<UserModel> _search(List<UserModel> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      final hay = '${u.fullName} ${u.phone} ${u.province ?? ''} ${u.district ?? ''} ${u.subdistrict ?? ''}'
          .toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  // Actions ------------------------------------------------------------------

  Future<void> _run(UserModel user, Future<void> Function() action, String done) async {
    if (_busy.contains(user.id)) return;
    setState(() => _busy.add(user.id));
    try {
      await action();
      if (mounted) AppToast.success(context, done);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, _message(e));
    } finally {
      if (mounted) setState(() => _busy.remove(user.id));
    }
  }

  String _message(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _approve(UserModel user) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'อนุมัติ ${user.fullName}?',
      message: _isSuperAdmin
          ? 'สมาชิกจะเข้าใช้งานระบบได้ทันที'
          : 'สมาชิกจะเข้าใช้งานได้ทันที และอยู่ในความดูแลของคุณ',
      confirmLabel: 'อนุมัติ',
      icon: AppIcons.checkCircle,
    );
    if (!ok || !mounted) return;
    final provider = context.read<AdminStateProvider>();
    await _run(user, () => provider.approveUser(user.id), 'อนุมัติ ${user.fullName} แล้ว');
  }

  Future<void> _reject(UserModel user) async {
    final reason = await AppDialogs.prompt(
      context,
      title: 'ไม่อนุมัติ ${user.fullName}',
      message: 'ผู้สมัครจะได้รับเหตุผลนี้ในการแจ้งเตือน',
      hint: 'เช่น ที่อยู่ไม่อยู่ในพื้นที่ให้บริการ',
      confirmLabel: 'ไม่อนุมัติ',
      destructive: true,
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    final provider = context.read<AdminStateProvider>();
    await _run(user, () => provider.rejectUser(user.id, reason), 'แจ้งผลให้ผู้สมัครแล้ว');
  }

  Future<void> _restore(UserModel user) async {
    final provider = context.read<AdminStateProvider>();
    await _run(user, () => provider.restoreUser(user.id), 'กู้คืน ${user.fullName} แล้ว');
  }

  Future<void> _delete(UserModel user) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ลบบัญชี ${user.fullName}?',
      message: 'บัญชีจะถูกปิดการใช้งาน และกู้คืนได้จากตัวกรอง "ถูกลบ"',
      confirmLabel: 'ลบบัญชี',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final service = context.read<SuperAdminService>();
    await _run(user, () async {
      await service.deleteUser(user.id);
      await _refresh();
    }, 'ลบบัญชีแล้ว');
  }

  Future<void> _changeRole(UserModel user) async {
    final role = await showAppSheet<UserRole>(
      context,
      title: 'สิทธิ์การใช้งาน',
      subtitle: user.fullName,
      child: _RolePicker(current: user.role),
    );
    if (role == null || role == user.role || !mounted) return;
    final provider = context.read<AdminStateProvider>();
    final code = switch (role) {
      UserRole.superAdmin => 'SUPER_ADMIN',
      UserRole.admin => 'ADMIN',
      UserRole.farmer => 'USER',
    };
    await _run(
      user,
      () => provider.updateUserRole(user.id, code),
      'เปลี่ยนเป็น${StatusLabels.role(role)}แล้ว',
    );
  }

  Future<void> _reassign(UserModel user) async {
    final service = context.read<AdminService>();
    List<dynamic> admins;
    try {
      admins = await service.getAdminList();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, _message(e));
      return;
    }
    if (!mounted) return;
    if (admins.isEmpty) {
      AppToast.info(context, 'ยังไม่มีเจ้าหน้าที่ในระบบ');
      return;
    }
    final adminId = await showAppSheet<String>(
      context,
      title: 'ย้ายไปให้เจ้าหน้าที่',
      subtitle: user.fullName,
      expand: true,
      child: _OfficerPicker(admins: admins),
    );
    if (adminId == null || !mounted) return;
    final provider = context.read<AdminStateProvider>();
    await _run(user, () async {
      await service.reassignUser(userId: user.id, newAdminId: adminId);
      await provider.loadUsers();
    }, 'ย้ายสมาชิกแล้ว');
  }

  void _openPlots(UserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminPlotListScreen(userId: user.id, userName: user.fullName),
      ),
    );
  }

  Future<void> _openDetail(UserModel user, {required bool deleted}) async {
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(user);
      return;
    }
    final action = await showAppSheet<_DetailAction>(
      context,
      child: _MemberDetail(user: user, deleted: deleted, superAdmin: _isSuperAdmin),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _DetailAction.plots:
        _openPlots(user);
      case _DetailAction.approve:
        await _approve(user);
      case _DetailAction.reject:
        await _reject(user);
      case _DetailAction.role:
        await _changeRole(user);
      case _DetailAction.reassign:
        await _reassign(user);
      case _DetailAction.delete:
        await _delete(user);
      case _DetailAction.restore:
        await _restore(user);
    }
  }

  // Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminStateProvider>();
    final me = context.watch<AuthProvider>().currentUser;
    final superAdmin = me?.role == UserRole.superAdmin;
    final users = _search(_source(state));
    final rejected = state.allUsers.where((u) => u.membershipStatus == MembershipStatus.rejected).length;
    final navSpace = widget.isEmbedded && context.isCompact ? 96.0 : Space.x4;

    return PageScaffold(
      title: superAdmin ? 'ผู้ใช้ทั้งหมด' : 'สมาชิก',
      subtitle: superAdmin
          ? '${state.allUsers.length} บัญชีในระบบ'
          : 'พื้นที่ ${staffScope(me)}',
      showBack: !widget.isEmbedded,
      onRefresh: _refresh,
      bottomPadding: navSpace,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                hint: 'ชื่อ เบอร์โทร หรือพื้นที่',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: Space.md),
              FilterChips<_Filter>(
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
                options: [
                  (_Filter.all, 'ทั้งหมด', state.allUsers.length),
                  (_Filter.pending, 'รออนุมัติ', state.pendingUsers.length),
                  (_Filter.approved, 'อนุมัติแล้ว', state.approvedUsers.length),
                  if (rejected > 0) (_Filter.rejected, 'ไม่อนุมัติ', rejected),
                  if (superAdmin) (_Filter.deleted, 'ถูกลบ', state.deletedUsers.length),
                ],
              ),
              const SizedBox(height: Space.lg),
            ],
          ),
        ),
        if (state.isLoading && state.allUsers.isEmpty)
          const SliverToBoxAdapter(child: SkeletonList(count: 5))
        else if (state.error != null && state.allUsers.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: ErrorState(message: state.error!, onRetry: _refresh),
            ),
          )
        else if (users.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: _query.isNotEmpty
                    ? 'ไม่พบผู้ที่ค้นหา'
                    : switch (_filter) {
                        _Filter.pending => 'ไม่มีใบสมัครค้างอยู่',
                        _Filter.deleted => 'ไม่มีบัญชีที่ถูกลบ',
                        _ => 'ยังไม่มีสมาชิก',
                      },
                message: _query.isNotEmpty
                    ? 'ลองค้นหาด้วยชื่อหรือเบอร์โทรอื่น'
                    : _filter == _Filter.pending
                        ? 'ใบสมัครใหม่ในพื้นที่จะแสดงที่นี่'
                        : null,
                mood: _filter == _Filter.pending ? MascotMood.joy : MascotMood.think,
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) {
              final user = users[i];
              final deleted = _filter == _Filter.deleted;
              return _MemberTile(
                user: user,
                showRole: superAdmin,
                deleted: deleted,
                busy: _busy.contains(user.id),
                onTap: () => _openDetail(user, deleted: deleted),
                onApprove: () => _approve(user),
                onReject: () => _reject(user),
                onRestore: () => _restore(user),
              ).entrance(context, index: i);
            },
          ),
      ],
    );
  }
}

// Tile ---------------------------------------------------------------------

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.user,
    required this.showRole,
    required this.deleted,
    required this.busy,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onRestore,
  });

  final UserModel user;
  final bool showRole;
  final bool deleted;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pending = !deleted && user.membershipStatus == MembershipStatus.pending;
    final (statusLabel, statusTone) = StatusLabels.membership(user.membershipStatus);
    final place = [
      if ((user.subdistrict ?? '').isNotEmpty) 'ต.${user.subdistrict}',
      if ((user.district ?? '').isNotEmpty) 'อ.${user.district}',
      if ((user.province ?? '').isNotEmpty) 'จ.${user.province}',
    ].join(' ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(name: user.fullName, photoUrl: user.photoUrl),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.isEmpty ? user.phone : '${user.phone} · $place',
                      style: context.text.bodySmall?.tabular,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              if (deleted)
                const StatusBadge(label: 'ถูกลบ', tone: Tone.danger)
              else if (showRole && user.role != UserRole.farmer)
                StatusBadge(
                  label: StatusLabels.role(user.role),
                  tone: Tone.info,
                  dot: false,
                  icon: user.role == UserRole.superAdmin ? AppIcons.superAdmin : AppIcons.officer,
                )
              else
                StatusBadge(label: statusLabel, tone: statusTone),
            ],
          ),
          if (pending || deleted) ...[
            const SizedBox(height: Space.md),
            Divider(height: 1, color: p.line),
            const SizedBox(height: Space.md),
            if (deleted)
              Align(
                alignment: Alignment.centerRight,
                child: AppButton.secondary(
                  label: 'กู้คืนบัญชี',
                  icon: AppIcons.undo,
                  size: ButtonSize.compact,
                  loading: busy,
                  onPressed: onRestore,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'ไม่อนุมัติ',
                      size: ButtonSize.compact,
                      onPressed: busy ? null : onReject,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: AppButton(
                      label: 'อนุมัติ',
                      icon: AppIcons.check,
                      size: ButtonSize.compact,
                      loading: busy,
                      onPressed: onApprove,
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

// Detail sheet --------------------------------------------------------------

enum _DetailAction { plots, approve, reject, role, reassign, delete, restore }

class _MemberDetail extends StatelessWidget {
  const _MemberDetail({required this.user, required this.deleted, required this.superAdmin});

  final UserModel user;
  final bool deleted;
  final bool superAdmin;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusTone) = StatusLabels.membership(user.membershipStatus);
    final approved = user.membershipStatus == MembershipStatus.approved;
    final pending = user.membershipStatus == MembershipStatus.pending;
    void pick(_DetailAction a) => Navigator.of(context).pop(a);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        Space.sm,
        Space.xl,
        Space.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(name: user.fullName, photoUrl: user.photoUrl, size: 56),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: context.text.headlineSmall),
                    Text(user.phone, style: context.text.bodyMedium?.mono),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (deleted)
                const StatusBadge(label: 'ถูกลบ', tone: Tone.danger)
              else
                StatusBadge(label: statusLabel, tone: statusTone),
              StatusBadge(label: StatusLabels.role(user.role), tone: Tone.neutral, dot: false),
            ],
          ),
          const SizedBox(height: Space.lg),
          ListGroup(
            children: [
              KeyValueRow(label: 'อาชีพ', value: user.job ?? 'ไม่ระบุ'),
              KeyValueRow(label: 'ตำบล', value: user.subdistrict ?? 'ไม่ระบุ'),
              KeyValueRow(label: 'อำเภอ', value: user.district ?? 'ไม่ระบุ'),
              KeyValueRow(label: 'จังหวัด', value: user.province ?? 'ไม่ระบุ'),
              KeyValueRow(
                label: 'วันเกิด',
                value: user.birthDate == null ? 'ไม่ระบุ' : ThaiDate.long(user.birthDate!),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          if (deleted)
            AppButton(
              label: 'กู้คืนบัญชี',
              icon: AppIcons.undo,
              expand: true,
              onPressed: () => pick(_DetailAction.restore),
            )
          else ...[
            if (pending)
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'ไม่อนุมัติ',
                      onPressed: () => pick(_DetailAction.reject),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: AppButton(
                      label: 'อนุมัติ',
                      icon: AppIcons.check,
                      onPressed: () => pick(_DetailAction.approve),
                    ),
                  ),
                ],
              ),
            if (approved && user.role == UserRole.farmer)
              AppButton.secondary(
                label: 'ดูแปลงของสมาชิก',
                icon: AppIcons.map,
                expand: true,
                onPressed: () => pick(_DetailAction.plots),
              ),
            if (superAdmin && approved) ...[
              const SizedBox(height: Space.md),
              ListGroup(
                children: [
                  ListRow(
                    icon: AppIcons.userSwitch,
                    title: 'เปลี่ยนสิทธิ์การใช้งาน',
                    subtitle: 'ปัจจุบัน: ${StatusLabels.role(user.role)}',
                    onTap: () => pick(_DetailAction.role),
                  ),
                  if (user.role == UserRole.farmer)
                    ListRow(
                      icon: AppIcons.officers,
                      title: 'ย้ายไปให้เจ้าหน้าที่คนอื่น',
                      onTap: () => pick(_DetailAction.reassign),
                    ),
                  ListRow(
                    icon: AppIcons.delete,
                    title: 'ลบบัญชี',
                    destructive: true,
                    onTap: () => pick(_DetailAction.delete),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RolePicker extends StatefulWidget {
  const _RolePicker({required this.current});

  final UserRole current;

  @override
  State<_RolePicker> createState() => _RolePickerState();
}

class _RolePickerState extends State<_RolePicker> {
  late UserRole _role = widget.current;

  static const _descriptions = {
    UserRole.farmer: 'บันทึกแปลงและข้อมูล GAP ของตนเอง',
    UserRole.admin: 'ตรวจแปลงและอนุมัติสมาชิกในพื้นที่ที่ได้รับมอบหมาย',
    UserRole.superAdmin: 'จัดการผู้ใช้ เจ้าหน้าที่ และข้อมูลทั้งระบบ',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final role in UserRole.values) ...[
            AppCard(
              onTap: () => setState(() => _role = role),
              padding: const EdgeInsets.all(Space.md + 2),
              color: _role == role ? p.brandSoft : p.surface,
              borderColor: _role == role ? p.brand : p.line,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(StatusLabels.role(role), style: context.text.titleSmall),
                        Text(_descriptions[role]!, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    _role == role ? AppIcons.checkCircleFill : AppIcons.checkCircle,
                    color: _role == role ? p.brand : p.lineStrong,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
          ],
          if (_role == UserRole.superAdmin && widget.current != UserRole.superAdmin)
            const Padding(
              padding: EdgeInsets.only(bottom: Space.sm),
              child: InlineBanner(
                tone: Tone.warning,
                title: 'สิทธิ์สูงสุดของระบบ',
                message: 'ผู้ดูแลระบบลบบัญชีและเปลี่ยนสิทธิ์ผู้อื่นได้ มอบให้เฉพาะผู้ที่ไว้ใจได้',
              ),
            ),
          const SizedBox(height: Space.sm),
          AppButton(
            label: 'บันทึก',
            expand: true,
            onPressed: _role == widget.current ? null : () => Navigator.of(context).pop(_role),
          ),
        ],
      ),
    );
  }
}

class _OfficerPicker extends StatelessWidget {
  const _OfficerPicker({required this.admins});

  final List<dynamic> admins;

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
        final a = Map<String, dynamic>.from(admins[i] as Map);
        final name = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim();
        final scope = [
          if ((a['district'] ?? '').toString().isNotEmpty) 'อ.${a['district']}',
          if ((a['province'] ?? '').toString().isNotEmpty) 'จ.${a['province']}',
        ].join(' ');
        return AppCard(
          padding: const EdgeInsets.all(Space.md),
          onTap: () => Navigator.of(context).pop(a['id']?.toString()),
          child: Row(
            children: [
              InitialsAvatar(name: name.isEmpty ? '?' : name, size: 40),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'ไม่ระบุชื่อ' : name, style: context.text.titleSmall),
                    Text(
                      scope.isEmpty ? '${a['phone'] ?? ''}' : '${a['phone'] ?? ''} · $scope',
                      style: context.text.bodySmall?.tabular,
                    ),
                  ],
                ),
              ),
              const Icon(AppIcons.chevronRight, size: 18),
            ],
          ),
        );
      },
    );
  }
}
