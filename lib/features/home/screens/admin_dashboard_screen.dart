import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/constants/legal_content.dart';
import '../../../core/constants/pdpa_content.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/notification_banner.dart';
import '../../../core/widgets/notification_icon.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../admin/providers/admin_state_provider.dart';
import '../../admin/screens/admin_plot_list_screen.dart';
import '../../admin/screens/admin_plots_map_screen.dart';
import '../../admin/screens/audit_log_screen.dart';
import '../../admin/screens/change_pin_screen.dart';
import '../../profile/screens/personal_info_screen.dart';
import '../../admin/screens/user_management_screen.dart';
import '../../auth/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../settings/screens/content_display_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/settings_provider.dart';

/// Where a staff member's authority applies, written out in Thai.
String staffScope(UserModel? user) {
  if (user == null) return '';
  if (user.role == UserRole.superAdmin) return 'ดูแลทุกพื้นที่';
  if ((user.subdistrict ?? '').isNotEmpty) {
    return 'ต.${user.subdistrict} อ.${user.district ?? '-'} จ.${user.province ?? '-'}';
  }
  if ((user.district ?? '').isNotEmpty) return 'อ.${user.district} จ.${user.province ?? '-'}';
  if ((user.province ?? '').isNotEmpty) return 'จ.${user.province}';
  if ((user.region ?? '').isNotEmpty) return user.region!;
  return 'ยังไม่ได้กำหนดพื้นที่';
}

/// Admin home: review queue, territory overview, members and map.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _shell = GlobalKey<AppShellState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.select<AdminStateProvider, int>((a) => a.pendingUsers.length);
    return AppShell(
      key: _shell,
      overlay: const StaffNotificationBanner(),
      railFooter: const StatusBadge(label: 'เจ้าหน้าที่', tone: Tone.brand),
      destinations: [
        ShellDestination(
          label: 'หน้าหลัก',
          icon: AppIcons.home,
          activeIcon: AppIcons.homeActive,
          page: AdminHomeScreen(onOpenMembers: () => _shell.currentState?.select(2)),
        ),
        const ShellDestination(
          label: 'แผนที่',
          icon: AppIcons.map,
          activeIcon: AppIcons.mapActive,
          page: AdminPlotsMapScreen(isMainTab: true),
        ),
        ShellDestination(
          label: 'สมาชิก',
          icon: AppIcons.members,
          activeIcon: AppIcons.membersActive,
          page: const UserManagementScreen(isEmbedded: true),
          badge: pending,
        ),
        const ShellDestination(
          label: 'บัญชี',
          icon: AppIcons.account,
          activeIcon: AppIcons.accountActive,
          page: AdminProfileScreen(),
        ),
      ],
    );
  }
}

/// In-app notification banner for staff shells.
class StaffNotificationBanner extends StatelessWidget {
  const StaffNotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final latest = provider.latestNotification;
    if (latest == null) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 4,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: NotificationBanner(
            notification: latest,
            onDismiss: provider.dismissBanner,
            onTap: () {
              provider.dismissBanner();
              context.push(Routes.notifications);
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Home
// ═══════════════════════════════════════════════════════════════════════

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, this.onOpenMembers});

  final VoidCallback? onOpenMembers;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loaded = false;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<AdminStateProvider>();
    await Future.wait([
      provider.loadStats(),
      provider.loadUsers(),
      provider.loadPendingPlots(),
      provider.loadAnalytics(),
    ]);
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _approve(UserModel user) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'อนุมัติสมาชิก',
      message: 'ยืนยันให้ ${user.fullName} เป็นสมาชิกในพื้นที่ของคุณ',
      confirmLabel: 'อนุมัติ',
      icon: AppIcons.userAdd,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(user.id));
    try {
      await context.read<AdminStateProvider>().approveUser(user.id);
      if (mounted) AppToast.success(context, 'อนุมัติ ${user.fullName} แล้ว');
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy.remove(user.id));
    }
  }

  Future<void> _reject(UserModel user) async {
    final reason = await AppDialogs.prompt(
      context,
      title: 'ไม่อนุมัติ ${user.firstName}',
      message: 'ระบุเหตุผล ระบบจะแจ้งผู้สมัครพร้อมเหตุผลนี้',
      hint: 'เช่น ข้อมูลที่ตั้งไม่ตรงกับพื้นที่',
      confirmLabel: 'ไม่อนุมัติ',
      destructive: true,
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _busy.add(user.id));
    try {
      await context.read<AdminStateProvider>().rejectUser(user.id, reason);
      if (mounted) AppToast.info(context, 'แจ้งผลไปยัง ${user.fullName} แล้ว');
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy.remove(user.id));
    }
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().user;
    final admin = context.watch<AdminStateProvider>();
    final stats = admin.stats;
    final pending = admin.pendingUsers;

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: p.brand,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: HeroHeader(
                maxWidth: 960,
                minHeight: 188,
                child: StaffGreeting(user: user, roleLabel: 'เจ้าหน้าที่', roleIcon: AppIcons.officer),
              ),
            ),
            SliverToBoxAdapter(
              child: SheetContainer(
                child: ContentWidth(
                  maxWidth: 960,
                  padding: EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.xs,
                    Space.gutter,
                    Space.x5 + 60 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdaptiveGrid(
                        minTileWidth: 150,
                        spacing: Space.sm,
                        children: [
                          StatTile(
                            value: stats['total'] ?? 0,
                            label: 'สมาชิกทั้งหมด',
                            icon: AppIcons.users,
                            dense: true,
                            onTap: widget.onOpenMembers,
                          ),
                          StatTile(
                            value: stats['pending'] ?? 0,
                            label: 'รออนุมัติสมาชิก',
                            icon: AppIcons.userAdd,
                            tone: Tone.warning,
                            dense: true,
                            onTap: widget.onOpenMembers,
                          ),
                          StatTile(
                            value: stats['pendingPlots'] ?? 0,
                            label: 'แปลงรอตรวจ',
                            icon: AppIcons.plot,
                            tone: Tone.warning,
                            dense: true,
                            onTap: () => _push(const AdminPlotListScreen(initialStatusFilter: 'PENDING')),
                          ),
                          StatTile(
                            value: admin.gapAnalytics?.plotsWithGap ?? 0,
                            label: 'แปลงมีบันทึก GAP',
                            icon: AppIcons.gap,
                            tone: Tone.success,
                            dense: true,
                          ),
                        ],
                      ).entrance(context),
                      const SizedBox(height: Space.xxl),
                      SectionHeader(
                        title: 'คำขอเป็นสมาชิก',
                        subtitle: pending.isEmpty ? null : 'รอการพิจารณา ${pending.length} ราย',
                        actionLabel: pending.length > 3 ? 'ดูทั้งหมด' : null,
                        onAction: widget.onOpenMembers,
                      ),
                      if (!_loaded && admin.isLoading)
                        const SkeletonList(count: 2, thumbnail: false)
                      else if (pending.isEmpty)
                        const AppCard(
                          child: EmptyState(
                            title: 'ไม่มีคำขอค้างพิจารณา',
                            message: 'คำขอใหม่จากเกษตรกรในพื้นที่จะแสดงที่นี่',
                            mood: MascotMood.joy,
                            compact: true,
                          ),
                        )
                      else
                        for (var i = 0; i < pending.length && i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: _RequestCard(
                              user: pending[i],
                              busy: _busy.contains(pending[i].id),
                              onApprove: () => _approve(pending[i]),
                              onReject: () => _reject(pending[i]),
                            ).entrance(context, index: i + 1),
                          ),
                      const SizedBox(height: Space.xl),
                      const SectionHeader(title: 'งานของเจ้าหน้าที่'),
                      AdaptiveGrid(
                        minTileWidth: 150,
                        spacing: Space.sm,
                        children: [
                          ShortcutCard(
                            icon: AppIcons.checklist,
                            title: 'ตรวจข้อมูล GAP',
                            caption: 'เลือกเกษตรกร แล้วดูแปลง',
                            onTap: () => _push(
                              UserManagementScreen(
                                onUserSelected: (u) {
                                  Navigator.of(context).pop();
                                  _push(AdminPlotListScreen(userId: u.id, userName: u.fullName));
                                },
                              ),
                            ),
                          ),
                          ShortcutCard(
                            icon: AppIcons.gap,
                            title: 'แปลงที่อนุมัติ',
                            caption: 'รายการและพิกัด',
                            onTap: () => _push(const AdminPlotListScreen(initialStatusFilter: 'APPROVED')),
                          ),
                          ShortcutCard(
                            icon: AppIcons.plot,
                            title: 'บันทึกแปลงแทน',
                            caption: 'สำหรับเกษตรกรที่ไม่สะดวก',
                            onTap: () => context.push(Routes.adminCreatePlot),
                          ),
                          ShortcutCard(
                            icon: AppIcons.chats,
                            title: 'ข้อความ',
                            caption: 'ติดต่อเจ้าหน้าที่อื่น',
                            onTap: () => context.push(Routes.adminMessages),
                          ),
                        ],
                      ).entrance(context, index: 3),
                      const SizedBox(height: Space.xxl),
                      const SectionHeader(title: 'ภาพรวมพื้นที่'),
                      LayoutBuilder(
                        builder: (context, c) {
                          final trend = TrendLineChart(
                            title: 'สมาชิกใหม่',
                            subtitle: '7 วันล่าสุด',
                            unit: ' คน',
                            points: [for (final t in admin.userTrends) TrendPoint(t.date, t.count)],
                          );
                          final gap = admin.gapAnalytics;
                          final total = gap?.totalPlots ?? 0;
                          final withGap = gap?.plotsWithGap ?? 0;
                          final breakdown = StatusBreakdownBar(
                            title: 'ความครอบคลุม GAP',
                            subtitle: 'แปลงที่มีบันทึกอย่างน้อยหนึ่งหมวด',
                            segments: [
                              StatusSegment('มีบันทึก GAP', withGap, ChartColors.approved(context)),
                              StatusSegment(
                                'ยังไม่มีบันทึก',
                                total > withGap ? total - withGap : 0,
                                ChartColors.none(context),
                              ),
                            ],
                          );
                          if (c.maxWidth < 720) {
                            return Column(
                              children: [
                                trend,
                                const SizedBox(height: Space.md),
                                breakdown,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: trend),
                              const SizedBox(width: Space.md),
                              Expanded(child: breakdown),
                            ],
                          );
                        },
                      ).entrance(context, index: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Greeting block on staff hero headers.
class StaffGreeting extends StatelessWidget {
  const StaffGreeting({super.key, required this.user, required this.roleLabel, required this.roleIcon});

  final UserModel? user;
  final String roleLabel;
  final IconData roleIcon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsAvatar(name: user?.fullName ?? '', photoUrl: user?.photoUrl, size: 44),
            const SizedBox(width: Space.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: Radii.chip),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 14, color: p.heroInk),
                  const SizedBox(width: 6),
                  Text(roleLabel, style: context.text.labelMedium?.copyWith(color: p.heroInk)),
                ],
              ),
            ),
            const Spacer(),
            const NotificationIcon(onHero: true),
          ],
        ),
        const SizedBox(height: Space.xl),
        Text(
          ThaiDate.greeting(),
          style: context.text.labelLarge?.copyWith(
            color: p.heroInk.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          user?.fullName.isNotEmpty == true ? user!.fullName : roleLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.headlineLarge?.copyWith(color: p.heroInk),
        ),
        const SizedBox(height: Space.xs),
        Row(
          children: [
            Icon(AppIcons.pin, size: 15, color: p.heroInk.withValues(alpha: 0.75)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'พื้นที่ดูแล: ${staffScope(user)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(color: p.heroInk.withValues(alpha: 0.78)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.user, required this.busy, required this.onApprove, required this.onReject});

  final UserModel user;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Space.md + 2),
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(name: user.fullName, photoUrl: user.photoUrl),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: context.text.titleSmall),
                    Text(
                      [user.phone, user.locationDisplay].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
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
      ),
    );
  }
}

/// Tile for a staff task shortcut.
class ShortcutCard extends StatelessWidget {
  const ShortcutCard({super.key, required this.icon, required this.title, required this.caption, required this.onTap});

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, size: 38),
          const SizedBox(height: Space.md),
          Text(title, style: context.text.titleSmall),
          Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Account
// ═══════════════════════════════════════════════════════════════════════

/// Account tab shared by admins and super admins.
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ออกจากระบบ',
      message: 'คุณต้องการออกจากระบบบนอุปกรณ์นี้ใช่หรือไม่',
      confirmLabel: 'ออกจากระบบ',
      destructive: true,
      icon: AppIcons.logout,
    );
    if (ok && context.mounted) await context.read<AuthProvider>().signOut();
  }

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().user;
    final version = context.select<SettingsProvider, String>((s) => s.version);
    final isSuper = user?.role == UserRole.superAdmin;

    return PageScaffold(
      title: 'บัญชีของฉัน',
      showBack: false,
      bottomPadding: 120,
      slivers: [
        SliverToBoxAdapter(
          child: AppCard(
            padding: const EdgeInsets.all(Space.xl),
            child: Row(
              children: [
                InitialsAvatar(name: user?.fullName ?? '', photoUrl: user?.photoUrl, size: 64),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '-', style: context.text.headlineSmall),
                      Text(user?.phone ?? '', style: context.text.bodyMedium?.copyWith(color: p.inkMuted).mono),
                      const SizedBox(height: Space.sm),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.xs,
                        children: [
                          StatusBadge(
                            label: isSuper ? 'ผู้ดูแลระบบ' : 'เจ้าหน้าที่',
                            tone: Tone.brand,
                            icon: isSuper ? AppIcons.superAdmin : AppIcons.officer,
                          ),
                          StatusBadge(label: staffScope(user), icon: AppIcons.pin),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).entrance(context),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        SliverToBoxAdapter(
          child: ListGroup(
            header: 'บัญชีและความปลอดภัย',
            children: [
              ListRow(
                icon: AppIcons.user,
                title: 'แก้ไขข้อมูลส่วนตัว',
                subtitle: 'ชื่อ เบอร์โทร และรูปโปรไฟล์',
                onTap: () => _push(context, const PersonalInfoScreen()),
              ),
              ListRow(
                icon: AppIcons.lock,
                title: 'เปลี่ยนรหัส PIN',
                subtitle: 'รหัส ${isSuper ? 8 : 6} หลักสำหรับเข้าใช้งาน',
                onTap: () => _push(context, const ChangePinScreen()),
              ),
            ],
          ).entrance(context, index: 1),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
        SliverToBoxAdapter(
          child: ListGroup(
            header: 'การทำงาน',
            children: [
              ListRow(
                icon: AppIcons.audit,
                title: 'ประวัติการทำรายการ',
                subtitle: 'การอนุมัติและแก้ไขข้อมูลที่ผ่านมา',
                onTap: () => isSuper ? context.push(Routes.superLogs) : _push(context, const AuditLogScreen()),
              ),
              ListRow(icon: AppIcons.chats, title: 'ข้อความ', onTap: () => context.push(Routes.adminMessages)),
              ListRow(
                icon: AppIcons.support,
                title: 'คำร้องขอความช่วยเหลือ',
                onTap: () => context.push(Routes.adminSupport),
              ),
            ],
          ).entrance(context, index: 2),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
        SliverToBoxAdapter(
          child: ListGroup(
            header: 'ทั่วไป',
            children: [
              ListRow(
                icon: AppIcons.settings,
                tone: Tone.neutral,
                title: 'ตั้งค่าแอป',
                subtitle: 'ธีม ขนาดตัวอักษร การแจ้งเตือน',
                onTap: () => _push(context, const SettingsScreen()),
              ),
              ListRow(
                icon: AppIcons.terms,
                tone: Tone.neutral,
                title: TermsContent.title,
                onTap: () =>
                    _push(context, const ContentDisplayScreen(title: TermsContent.title, content: TermsContent.body)),
              ),
              ListRow(
                icon: AppIcons.privacy,
                tone: Tone.neutral,
                title: 'นโยบายความเป็นส่วนตัว (PDPA)',
                onTap: () => _push(
                  context,
                  const ContentDisplayScreen(
                    title: PdpaContent.title,
                    content: '${PdpaContent.fullContent}\n\n${PdpaContent.references}',
                  ),
                ),
              ),
              ListRow(
                icon: AppIcons.logout,
                title: 'ออกจากระบบ',
                destructive: true,
                showChevron: false,
                onTap: () => _logout(context),
              ),
            ],
          ).entrance(context, index: 3),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: Space.x3),
            child: Column(
              children: [
                const LogoMark(size: 28),
                const SizedBox(height: Space.sm),
                Text(
                  'TAPTOM ${isSuper ? 'Console' : 'Staff'}${version.isEmpty ? '' : ' v$version'}',
                  style: context.text.labelMedium,
                ),
                const SizedBox(height: Space.xl),
                const DevelopedBy(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
