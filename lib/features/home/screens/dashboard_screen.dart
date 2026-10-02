import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/plot_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/notification_banner.dart';
import '../../../core/widgets/notification_icon.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../auth/widgets/gap_info_sheet.dart';
import '../../certificate/screens/certificate_list_screen.dart';
import '../../contact/screens/contact_screen.dart';
import '../../gap/screens/gap_main_screen.dart';
import '../../gap/screens/request_history_screen.dart';
import '../../map/screens/map_drawing_screen.dart';
import '../../map/screens/my_plots_map_screen.dart';
import '../../map/screens/plot_detail_screen.dart';
import '../../map/widgets/plot_card.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../profile/screens/personal_info_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/settings_provider.dart';
import '../widgets/news_carousel.dart';
import 'gap_records_screen.dart';

/// Farmer home: four tabs, notification polling and the in-app banner.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _shell = GlobalKey<AppShellState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<NotificationProvider>().startPolling();
      // Ask for notification permission after the farmer has seen the app,
      // not on first launch.
      if (context.read<SettingsProvider>().notificationsEnabled) {
        try {
          await PermissionService.requestNotificationPermission();
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationProvider, int>((n) => n.unreadCount);
    return AppShell(
      key: _shell,
      overlay: const _BannerOverlay(),
      railFooter: const _RoleChip(label: 'เกษตรกร'),
      destinations: [
        ShellDestination(
          label: 'หน้าแรก',
          icon: AppIcons.home,
          activeIcon: AppIcons.homeActive,
          page: FarmerHomeTab(onOpenRecords: () => _shell.currentState?.select(2)),
          badge: unread,
        ),
        const ShellDestination(
          label: 'แผนที่',
          icon: AppIcons.map,
          activeIcon: AppIcons.mapActive,
          page: MyPlotsMapScreen(embedded: true),
        ),
        const ShellDestination(
          label: 'บันทึก GAP',
          icon: AppIcons.records,
          activeIcon: AppIcons.recordsActive,
          page: GapRecordsScreen(),
        ),
        const ShellDestination(
          label: 'บัญชี',
          icon: AppIcons.account,
          activeIcon: AppIcons.accountActive,
          page: FarmerAccountTab(),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => StatusBadge(label: label, tone: Tone.brand);
}

class _BannerOverlay extends StatelessWidget {
  const _BannerOverlay();

  @override
  Widget build(BuildContext context) {
    final latest = context.select<NotificationProvider, dynamic>((n) => n.latestNotification);
    if (latest == null) return const SizedBox.shrink();
    final provider = context.read<NotificationProvider>();
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 4,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: NotificationBanner(
            notification: provider.latestNotification!,
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
// Home tab
// ═══════════════════════════════════════════════════════════════════════

/// Daily overview: greeting, plot counts, quick actions, plots and news.
class FarmerHomeTab extends StatefulWidget {
  const FarmerHomeTab({super.key, this.onOpenRecords});

  final VoidCallback? onOpenRecords;

  @override
  State<FarmerHomeTab> createState() => _FarmerHomeTabState();
}

class _FarmerHomeTabState extends State<FarmerHomeTab> {
  List<PlotModel>? _plots;
  Object? _error;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final plots = await context.read<PlotService>().getMyPlots();
      if (mounted) setState(() => _plots = plots);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _openPlot(PlotModel plot) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlotDetailScreen(plot: plot)),
    );
    if (changed == true) _load();
  }

  Future<void> _drawPlot() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapDrawingScreen()),
    );
    _load();
  }

  void _pickPlotForGap() {
    final plots = _plots ?? const <PlotModel>[];
    showAppSheet<void>(
      context,
      title: 'บันทึก GAP',
      subtitle: 'เลือกแปลงที่ต้องการบันทึก',
      child: plots.isEmpty
          ? EmptyState(
              title: 'ยังไม่มีแปลง',
              message: 'วาดขอบเขตแปลงบนแผนที่ก่อน แล้วจึงบันทึก GAP',
              actionLabel: 'วาดแปลงใหม่',
              onAction: () {
                Navigator.of(context).pop();
                _drawPlot();
              },
              compact: true,
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, Space.x3),
              itemCount: plots.length,
              separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
              itemBuilder: (sheetContext, i) => PlotCard(
                plot: plots[i],
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GapMainScreen(
                        plotId: plots[i].id ?? '',
                        plotName: plots[i].name,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().user;
    final offline = context.select<AuthProvider, bool>((a) => a.isOffline);
    final plots = _plots;

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: p.brand,
        edgeOffset: MediaQuery.paddingOf(context).top,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: HeroHeader(
                minHeight: 196,
                trailing: context.isCompact
                    ? const FarmerMascot(size: 104, mood: MascotMood.wave)
                    : const FarmerMascot(size: 132, mood: MascotMood.wave),
                child: _greeting(context, user, plots, offline),
              ),
            ),
            SliverToBoxAdapter(
              child: SheetContainer(
                child: ContentWidth(
                  padding: EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.xs,
                    Space.gutter,
                    Space.x5 + MediaQuery.paddingOf(context).bottom + 40,
                  ),
                  child: _body(context, plots),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _greeting(
    BuildContext context,
    UserModel? user,
    List<PlotModel>? plots,
    bool offline,
  ) {
    final p = context.palette;
    final pending = plots?.where((x) => x.status == 'PENDING').length ?? 0;
    final summary = plots == null
        ? 'กำลังโหลดข้อมูลแปลง'
        : plots.isEmpty
            ? 'เริ่มต้นด้วยการวาดแปลงแรกของคุณ'
            : 'มี ${plots.length} แปลงในความดูแล${pending > 0 ? ' · รอตรวจสอบ $pending' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsAvatar(
              name: user?.fullName ?? 'เกษตรกร',
              photoUrl: user?.photoUrl,
              size: 44,
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
        Padding(
          padding: EdgeInsets.only(right: context.isCompact ? 96 : 140),
          child: Text(
            user?.firstName.isNotEmpty == true ? 'คุณ${user!.firstName}' : 'เกษตรกร',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.headlineLarge?.copyWith(color: p.heroInk),
          ),
        ),
        const SizedBox(height: Space.xs),
        Padding(
          padding: EdgeInsets.only(right: context.isCompact ? 96 : 140),
          child: Text(
            summary,
            style: context.text.bodyMedium?.copyWith(
              color: p.heroInk.withValues(alpha: 0.78),
            ),
          ),
        ),
        if (offline) ...[
          const SizedBox(height: Space.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: Radii.chip,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.offline, size: 14, color: p.heroInk),
                const SizedBox(width: 6),
                Text(
                  'ออฟไลน์ แสดงข้อมูลล่าสุดที่บันทึกไว้',
                  style: context.text.labelMedium?.copyWith(color: p.heroInk),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _body(BuildContext context, List<PlotModel>? plots) {
    final total = plots?.length ?? 0;
    final pending = plots?.where((x) => x.status == 'PENDING').length ?? 0;
    final approved = plots?.where((x) => x.status == 'APPROVED').length ?? 0;
    final rejected = plots?.where((x) => x.status == 'REJECTED').toList() ?? const [];
    final visible = _filter == null
        ? (plots ?? const <PlotModel>[])
        : (plots ?? const <PlotModel>[]).where((x) => x.status == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: total,
                label: 'แปลงทั้งหมด',
                icon: AppIcons.plot,
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
                dense: true,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: StatTile(
                value: pending,
                label: 'รอตรวจสอบ',
                icon: AppIcons.pending,
                tone: Tone.warning,
                selected: _filter == 'PENDING',
                onTap: () => setState(() => _filter = _filter == 'PENDING' ? null : 'PENDING'),
                dense: true,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: StatTile(
                value: approved,
                label: 'อนุมัติแล้ว',
                icon: AppIcons.gap,
                tone: Tone.success,
                selected: _filter == 'APPROVED',
                onTap: () => setState(() => _filter = _filter == 'APPROVED' ? null : 'APPROVED'),
                dense: true,
              ),
            ),
          ],
        ).entrance(context),
        const SizedBox(height: Space.xxl),
        const SectionHeader(title: 'ทางลัด'),
        AdaptiveGrid(
          minTileWidth: 150,
          maxColumns: 4,
          children: [
            _QuickAction(
              icon: AppIcons.plot,
              title: 'วาดแปลงใหม่',
              caption: 'กำหนดขอบเขตบนแผนที่',
              onTap: _drawPlot,
            ),
            _QuickAction(
              icon: AppIcons.clipboard,
              title: 'บันทึก GAP',
              caption: 'กรอกข้อมูล 7 หมวด',
              onTap: _pickPlotForGap,
            ),
            _QuickAction(
              icon: AppIcons.certificate,
              title: 'ใบรับรอง',
              caption: 'ดาวน์โหลดและแชร์',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CertificateListScreen()),
              ),
            ),
            _QuickAction(
              icon: AppIcons.scan,
              title: 'สแกนตรวจสอบ',
              caption: 'อ่าน QR ของล็อต',
              onTap: () => context.push(Routes.traceabilityScan),
            ),
          ],
        ).entrance(context, index: 1),
        const SizedBox(height: Space.md),
        _AskLungTom(onTap: () => context.push(Routes.chat)).entrance(context, index: 2),
        if (rejected.isNotEmpty) ...[
          const SizedBox(height: Space.xl),
          InlineBanner(
            tone: Tone.danger,
            title: 'มี ${rejected.length} แปลงไม่ผ่านการตรวจ',
            message: 'แก้ไขข้อมูลตามคำแนะนำของเจ้าหน้าที่ แล้วส่งตรวจอีกครั้ง',
            action: TextButton(
              onPressed: () => _openPlot(rejected.first),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
              child: Text('ดู ${rejected.first.name}'),
            ),
          ).entrance(context, index: 2),
        ],
        const SizedBox(height: Space.xxl),
        SectionHeader(
          title: 'แปลงของฉัน',
          subtitle: _filter == null ? null : 'กรองตามสถานะ: ${StatusLabels.plot(_filter).$1}',
          actionLabel: total > 0 ? 'เพิ่มแปลง' : null,
          onAction: _drawPlot,
        ),
        if (plots == null && _error == null)
          const SkeletonList(count: 3)
        else if (_error != null)
          AppCard(child: ErrorState(onRetry: _load, compact: true))
        else if (total == 0)
          AppCard(
            child: EmptyState(
              title: 'ยังไม่มีแปลงที่ลงทะเบียน',
              message: 'วาดขอบเขตแปลงบนแผนที่เพื่อเริ่มบันทึกข้อมูล GAP',
              mood: MascotMood.happy,
              actionLabel: 'วาดแปลงแรก',
              onAction: _drawPlot,
              compact: true,
            ),
          )
        else if (visible.isEmpty)
          AppCard(
            child: EmptyState(
              title: 'ไม่มีแปลงในสถานะนี้',
              icon: AppIcons.filter,
              actionLabel: 'ดูทั้งหมด',
              onAction: () => setState(() => _filter = null),
              compact: true,
            ),
          )
        else
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: PlotCard(plot: visible[i], onTap: () => _openPlot(visible[i]))
                  .entrance(context, index: i + 2),
            ),
        const SizedBox(height: Space.xl),
        const SectionHeader(title: 'ข่าวสารและความรู้'),
        const NewsCarousel(),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

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
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Account tab
// ═══════════════════════════════════════════════════════════════════════

/// Farmer profile summary and settings entry points.
class FarmerAccountTab extends StatelessWidget {
  const FarmerAccountTab({super.key});

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

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().user;
    final version = context.select<SettingsProvider, String>((s) => s.version);
    final (memberLabel, memberTone) = StatusLabels.membership(
      user?.membershipStatus ?? MembershipStatus.none,
    );

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
                InitialsAvatar(
                  name: user?.fullName ?? '',
                  photoUrl: user?.photoUrl,
                  size: 64,
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '-',
                        style: context.text.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.phone ?? '',
                        style: context.text.bodyMedium?.copyWith(color: p.inkMuted).mono,
                      ),
                      const SizedBox(height: Space.sm),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.xs,
                        children: [
                          StatusBadge(label: memberLabel, tone: memberTone),
                          if (user != null && user.locationDisplay != 'ไม่ระบุ')
                            StatusBadge(
                              label: user.province ?? user.locationDisplay,
                              icon: AppIcons.pin,
                            ),
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
            header: 'ข้อมูลของฉัน',
            children: [
              ListRow(
                icon: AppIcons.user,
                title: 'ข้อมูลส่วนตัว',
                subtitle: 'ชื่อ ที่อยู่ และอาชีพ',
                onTap: () => _push(context, const PersonalInfoScreen()),
              ),
              ListRow(
                icon: AppIcons.map,
                title: 'แปลงบนแผนที่',
                onTap: () => _push(context, const MyPlotsMapScreen()),
              ),
              ListRow(
                icon: AppIcons.history,
                title: 'ประวัติการยื่นขอ',
                subtitle: 'สถานะการตรวจของแต่ละแปลง',
                onTap: () => _push(context, const RequestHistoryScreen()),
              ),
              ListRow(
                icon: AppIcons.certificate,
                title: 'ใบรับรอง GAP',
                onTap: () => _push(context, const CertificateListScreen()),
              ),
            ],
          ).entrance(context, index: 1),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
        SliverToBoxAdapter(
          child: ListGroup(
            header: 'ความช่วยเหลือ',
            children: [
              ListRow(
                icon: AppIcons.chat,
                title: 'ถามลุงต้อม',
                subtitle: 'ผู้ช่วยเรื่องการปลูกและ GAP',
                onTap: () => context.push(Routes.chat),
              ),
              ListRow(
                icon: AppIcons.building,
                title: 'ติดต่อเจ้าหน้าที่',
                onTap: () => _push(context, const ContactScreen()),
              ),
              ListRow(
                icon: AppIcons.support,
                title: 'แจ้งปัญหาการใช้งาน',
                onTap: () => context.push(Routes.supportTickets),
              ),
              ListRow(
                icon: AppIcons.gap,
                title: 'มาตรฐาน GAP คืออะไร',
                onTap: () => showGapInfoSheet(context),
              ),
            ],
          ).entrance(context, index: 2),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
        SliverToBoxAdapter(
          child: ListGroup(
            children: [
              ListRow(
                icon: AppIcons.settings,
                tone: Tone.neutral,
                title: 'ตั้งค่า',
                subtitle: 'ธีม ขนาดตัวอักษร การแจ้งเตือน',
                onTap: () => _push(context, const SettingsScreen()),
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
                  'TAPTOM ${version.isEmpty ? '' : 'v$version'}',
                  style: context.text.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Entry to the assistant: Lung Tom leaning in from the left.
class _AskLungTom extends StatelessWidget {
  const _AskLungTom({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.lg, Space.sm),
      color: p.brandSoft,
      borderColor: Colors.transparent,
      child: Row(
        children: [
          const FarmerMascot(size: 64, mood: MascotMood.think, animated: false),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ถามลุงต้อม', style: context.text.titleSmall?.copyWith(color: p.brandStrong)),
                Text(
                  'สงสัยเรื่องปุ๋ย โรคพืช หรือขั้นตอน GAP ถามได้ทุกเมื่อ',
                  style: context.text.bodySmall?.copyWith(color: p.ink),
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, color: p.brandStrong, size: 20),
        ],
      ),
    );
  }
}
