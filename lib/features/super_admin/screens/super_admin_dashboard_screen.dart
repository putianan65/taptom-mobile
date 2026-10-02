import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/services/super_admin_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/analytics_model.dart';
import '../../admin/screens/admin_plots_map_screen.dart';
import '../../admin/screens/user_management_screen.dart';
import '../../auth/auth_provider.dart';
import '../../home/screens/admin_dashboard_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import 'admin_management_screen.dart';

/// Super admin console: platform overview, all users, the national map and
/// officer management.
class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
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
    return AppShell(
      key: _shell,
      overlay: const StaffNotificationBanner(),
      railFooter: const StatusBadge(
        label: 'ผู้ดูแลระบบ',
        tone: Tone.brand,
        icon: AppIcons.superAdmin,
      ),
      destinations: [
        ShellDestination(
          label: 'ภาพรวม',
          icon: AppIcons.overview,
          activeIcon: AppIcons.overviewActive,
          page: SuperAdminHomeScreen(onSelectTab: (i) => _shell.currentState?.select(i)),
        ),
        const ShellDestination(
          label: 'ผู้ใช้',
          icon: AppIcons.members,
          activeIcon: AppIcons.membersActive,
          page: UserManagementScreen(isEmbedded: true),
        ),
        const ShellDestination(
          label: 'แผนที่',
          icon: AppIcons.map,
          activeIcon: AppIcons.mapActive,
          page: AdminPlotsMapScreen(isMainTab: true),
        ),
        const ShellDestination(
          label: 'เจ้าหน้าที่',
          icon: AppIcons.officers,
          activeIcon: AppIcons.officersActive,
          page: AdminManagementScreen(isEmbedded: true),
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

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  Map<String, dynamic>? _stats;
  List<UserTrendsData> _trends = [];
  String _period = '7d';
  bool _loadingTrends = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<SuperAdminService>();
    final results = await Future.wait([
      service.getSystemStats(),
      service.getRegistrationTrends(period: _period),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0] as Map<String, dynamic>;
      _trends = _parseTrends(results[1] as List<dynamic>);
    });
  }

  List<UserTrendsData> _parseTrends(List<dynamic> raw) {
    final out = <UserTrendsData>[];
    for (final e in raw) {
      try {
        out.add(UserTrendsData.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    return out;
  }

  Future<void> _changePeriod(String period) async {
    setState(() {
      _period = period;
      _loadingTrends = true;
    });
    final raw = await context.read<SuperAdminService>().getRegistrationTrends(period: period);
    if (!mounted) return;
    setState(() {
      _trends = _parseTrends(raw);
      _loadingTrends = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().user;
    final s = _stats;
    int n(String key) => (s?[key] as num?)?.toInt() ?? 0;

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
                minHeight: 188,
                child: StaffGreeting(
                  user: user,
                  roleLabel: 'ผู้ดูแลระบบ',
                  roleIcon: AppIcons.superAdmin,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SheetContainer(
                child: ContentWidth(
                  maxWidth: 1040,
                  padding: EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.xs,
                    Space.gutter,
                    Space.x5 + 60 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (s == null)
                        const SkeletonDashboardGrid()
                      else
                        AdaptiveGrid(
                          minTileWidth: 150,
                          spacing: Space.sm,
                          children: [
                            StatTile(
                              value: n('totalUsers'),
                              label: 'ผู้ใช้ทั้งหมด',
                              icon: AppIcons.users,
                              dense: true,
                              onTap: () => widget.onSelectTab?.call(1),
                            ),
                            StatTile(
                              value: n('totalAdmins'),
                              label: 'เจ้าหน้าที่',
                              icon: AppIcons.officer,
                              dense: true,
                              onTap: () => widget.onSelectTab?.call(3),
                            ),
                            StatTile(
                              value: n('totalPlots'),
                              label: 'แปลงทั้งหมด',
                              icon: AppIcons.plot,
                              dense: true,
                              onTap: () => widget.onSelectTab?.call(2),
                            ),
                            StatTile(
                              value: (s['totalArea'] as num?) ?? 0,
                              label: 'พื้นที่รวม (ไร่)',
                              icon: AppIcons.area,
                              dense: true,
                            ),
                            StatTile(
                              value: n('pendingUsers'),
                              label: 'สมาชิกรออนุมัติ',
                              icon: AppIcons.userAdd,
                              tone: Tone.warning,
                              dense: true,
                              onTap: () => widget.onSelectTab?.call(1),
                            ),
                            StatTile(
                              value: n('pendingPlots'),
                              label: 'แปลงรอตรวจ',
                              icon: AppIcons.pending,
                              tone: Tone.warning,
                              dense: true,
                              onTap: () => widget.onSelectTab?.call(2),
                            ),
                          ],
                        ).entrance(context),
                      const SizedBox(height: Space.xxl),
                      Row(
                        children: [
                          const Expanded(child: SectionHeader(title: 'การเติบโตของผู้ใช้')),
                          SizedBox(
                            width: 168,
                            child: SegmentedTabs<String>(
                              segments: const [('7d', '7 วัน'), ('30d', '30 วัน')],
                              value: _period,
                              onChanged: _changePeriod,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.sm),
                      LayoutBuilder(
                        builder: (context, c) {
                          final trend = AnimatedOpacity(
                            opacity: _loadingTrends ? 0.5 : 1,
                            duration: Motion.quick,
                            child: TrendLineChart(
                              title: 'ผู้ลงทะเบียนใหม่',
                              subtitle: _period == '7d' ? '7 วันล่าสุด' : '30 วันล่าสุด',
                              unit: ' คน',
                              points: [for (final t in _trends) TrendPoint(t.date, t.count)],
                            ),
                          );
                          final total = n('totalUsers');
                          final farmers = n('farmers');
                          final pending = n('pendingUsers');
                          final staff = total - farmers;
                          final breakdown = StatusBreakdownBar(
                            title: 'สถานะผู้ใช้',
                            subtitle: 'สมาชิกทั้งระบบ',
                            segments: [
                              StatusSegment(
                                'เกษตรกรที่อนุมัติแล้ว',
                                farmers > pending ? farmers - pending : 0,
                                ChartColors.approved(context),
                              ),
                              StatusSegment('รออนุมัติ', pending, ChartColors.pending(context)),
                              StatusSegment(
                                'เจ้าหน้าที่และผู้ดูแล',
                                staff > 0 ? staff : n('totalAdmins'),
                                ChartColors.none(context),
                              ),
                            ],
                          );
                          if (c.maxWidth < 760) {
                            return Column(
                              children: [trend, const SizedBox(height: Space.md), breakdown],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: trend),
                              const SizedBox(width: Space.md),
                              Expanded(flex: 2, child: breakdown),
                            ],
                          );
                        },
                      ).entrance(context, index: 1),
                      const SizedBox(height: Space.xxl),
                      const SectionHeader(title: 'จัดการระบบ'),
                      AdaptiveGrid(
                        minTileWidth: 150,
                        spacing: Space.sm,
                        children: [
                          ShortcutCard(
                            icon: AppIcons.userAdd,
                            title: 'เพิ่มเจ้าหน้าที่',
                            caption: 'กำหนดพื้นที่ดูแล',
                            onTap: () => context.push(Routes.superAdminCreate),
                          ),
                          ShortcutCard(
                            icon: AppIcons.officers,
                            title: 'เจ้าหน้าที่ทั้งหมด',
                            caption: 'มอบหมายและย้ายสมาชิก',
                            onTap: () => widget.onSelectTab?.call(3),
                          ),
                          ShortcutCard(
                            icon: AppIcons.audit,
                            title: 'บันทึกระบบ',
                            caption: 'ใครทำอะไร เมื่อไร',
                            onTap: () => context.push(Routes.superLogs),
                          ),
                          ShortcutCard(
                            icon: AppIcons.chats,
                            title: 'ข้อความ',
                            caption: 'ติดต่อเจ้าหน้าที่',
                            onTap: () => context.push(Routes.adminMessages),
                          ),
                        ],
                      ).entrance(context, index: 2),
                      if (n('riskyPlots') > 0) ...[
                        const SizedBox(height: Space.xl),
                        InlineBanner(
                          tone: Tone.warning,
                          title: 'แปลงที่ควรติดตาม ${n('riskyPlots')} แปลง',
                          message: 'แปลงที่ข้อมูล GAP ไม่ครบหรือใกล้ครบกำหนดตรวจ ตรวจสอบได้จากแผนที่',
                        ),
                      ],
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

/// Placeholder grid while console stats load.
class SkeletonDashboardGrid extends StatelessWidget {
  const SkeletonDashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: AdaptiveGrid(
        minTileWidth: 150,
        spacing: Space.sm,
        children: [
          for (var i = 0; i < 6; i++) const SkeletonBox(height: 82, radius: Radii.lg),
        ],
      ),
    );
  }
}
