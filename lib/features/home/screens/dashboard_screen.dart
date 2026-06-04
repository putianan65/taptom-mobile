import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/config/env.dart';
import '../../map/screens/map_drawing_screen.dart';
import '../../gap/screens/gap_main_screen.dart';
import '../widgets/news_carousel.dart';
import '../../auth/auth_provider.dart';
import '../../../core/widgets/nature_background.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/services/plot_service.dart';
import '../../../data/models/plot_model.dart';
import '../../map/screens/plot_detail_screen.dart';
import '../../contact/screens/contact_screen.dart';
import '../../../core/widgets/notification_banner.dart';
import '../../../data/models/notification_model.dart';
import '../../map/screens/my_plots_map_screen.dart';
import '../../certificate/screens/certificate_list_screen.dart';
import '../../profile/screens/personal_info_screen.dart';
import '../../gap/screens/request_history_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/dashboard_menu_item.dart';
import 'gap_records_screen.dart';
import '../../settings/settings_provider.dart';
import '../../notifications/providers/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const MapDrawingScreen(),
    const GapRecordsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Start notification polling when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _pages[_selectedIndex],

          // ✅ Notification Banner (overlay ด้านบน)
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              if (notifProvider.latestNotification == null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: MediaQuery.of(context).padding.top + 4,
                left: 0,
                right: 0,
                child: NotificationBanner(
                  notification: notifProvider.latestNotification!,
                  onDismiss: () => notifProvider.dismissBanner(),
                  onTap: () {
                    notifProvider.dismissBanner();
                    context.push('/notifications');
                  },
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      // ── AI Chat Button (disabled - API rate limit issues) ──
      // floatingActionButton: _selectedIndex == 0
      //     ? FloatingActionButton.extended(
      //         onPressed: () => context.push('/chat'),
      //         backgroundColor: AppColors.primary,
      //         elevation: 2,
      //         icon: const HeroIcon(
      //           HeroIcons.sparkles,
      //           style: HeroIconStyle.outline,
      //           color: Colors.white,
      //           size: 20,
      //         ),
      //         label: Text(
      //           'AI ช่วยเหลือ',
      //           style: GoogleFonts.prompt(
      //             fontWeight: FontWeight.w600,
      //             color: Colors.white,
      //             fontSize: 14,
      //           ),
      //         ),
      //       )
      //     : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 12, color: AppColors.shadowLight)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: GNav(
            rippleColor: AppColors.primaryLighter.withOpacity(0.2),
            hoverColor: AppColors.primaryLighter.withOpacity(0.1),
            gap: 8,
            activeColor: Colors.white,
            iconSize: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: const Duration(milliseconds: 300),
            tabBackgroundColor: AppColors.primary,
            color: AppColors.textSecondary,
            tabs: const [
              GButton(icon: Icons.home_outlined, text: 'หน้าแรก'),
              GButton(icon: Icons.map_outlined, text: 'แผนที่'),
              GButton(icon: Icons.assignment_outlined, text: 'บันทึก'),
              GButton(icon: Icons.person_outline, text: 'บัญชี'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOME SCREEN - Clean, Modern Dashboard
// ══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PlotModel>> _plotsFuture;
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadPlots();
  }

  void _loadPlots() {
    final plotService = context.read<PlotService>();
    setState(() {
      _plotsFuture = plotService.getMyPlots();
    });
  }

  void _toggleFilter(String? status) {
    setState(() {
      _selectedStatusFilter = (_selectedStatusFilter == status) ? null : status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Header with gradient
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: _buildHeader(),
              ),
            ),

            // Content area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async => _loadPlots(),
                    color: AppColors.primary,
                    child: FutureBuilder<List<PlotModel>>(
                      future: _plotsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingState();
                        }

                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error);
                        }

                        final allPlots = snapshot.data ?? [];
                        final visiblePlots = _selectedStatusFilter == null
                            ? allPlots
                            : allPlots
                                  .where(
                                    (p) => p.status == _selectedStatusFilter,
                                  )
                                  .toList();

                        return _buildContentState(allPlots, visiblePlots);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final firstName = user?.firstName ?? 'เกษตรกร';
        final initial = firstName.isNotEmpty ? firstName[0] : 'U';

        final hour = DateTime.now().hour;
        String greeting = hour < 12
            ? 'สวัสดีตอนเช้า'
            : hour < 17
            ? 'สวัสดีตอนบ่าย'
            : 'สวัสดีตอนเย็น';

        return Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: GoogleFonts.prompt(
                  color: AppColors.primary,
                  fontSize: 24, // Increased from 20
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8), // Reduced from 12
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                      height: 1.1, // 💡 Snug but not tight
                    ),
                  ),
                  // Removed SizedBox for natural flow
                  Text(
                    user != null
                        ? '${user.firstName} ${user.lastName}'
                        : 'เกษตรกร',
                    style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                      height: 1.1, // 💡 Snug but not tight
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Notification button (Enhanced Visibility)
            // Notification button (Guided by Settings)
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                if (!settings.notificationsEnabled) return const SizedBox.shrink();
                
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Solid white for contrast
                    borderRadius: BorderRadius.circular(14), // Slightly rounder
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showNotifications(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12), // Larger touch area
                        child: HeroIcon(
                          HeroIcons.bell,
                          style: HeroIconStyle.solid, // Solid style for impact
                          color: AppColors.primary, // Primary color for icon
                          size: 24, // Increased from 20
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          NewsCarousel(),
          SizedBox(height: 24),
          SkeletonPlotCard(count: 3),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HeroIcon(
                HeroIcons.exclamationTriangle,
                size: 40,
                color: AppColors.error,
                style: HeroIconStyle.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'ไม่สามารถโหลดข้อมูล',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString().replaceAll('Exception: ', ''),
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(() => _loadPlots()),
                child: Text(
                  'ลองใหม่',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentState(
    List<PlotModel> allPlots,
    List<PlotModel> visiblePlots,
  ) {
    final totalCount = allPlots.length;
    final pendingCount = allPlots.where((p) => p.status == 'PENDING').length;
    final approvedCount = allPlots.where((p) => p.status == 'APPROVED').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NewsCarousel(),
          const SizedBox(height: 24),

          _buildSectionTitle('ทางลัด'),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 24),

          _buildStatsBar(totalCount, pendingCount, approvedCount),
          const SizedBox(height: 20),

          _buildPlotListHeader(),
          const SizedBox(height: 12),

          visiblePlots.isEmpty
              ? _buildEmptyPlots()
              : _buildPlotsList(visiblePlots),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.prompt(
        fontSize: 20, // Increased from 17
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionCard(
          icon: HeroIcons.map,
          label: 'ดูแผนที่',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyPlotsMapScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _buildActionCard(
          icon: HeroIcons.clipboardDocumentList,
          label: 'บันทึก GAP',
          onTap: () => _showPlotSelector(context),
        ),
        const SizedBox(width: 10),
        _buildActionCard(
          icon: HeroIcons.documentCheck,
          label: 'ใบรับรอง',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CertificateListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required HeroIcons icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Increased padding
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: HeroIcon(
                    icon,
                    color: AppColors.primary,
                    size: 26, // Increased from 22
                    style: HeroIconStyle.outline,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.prompt(
                    fontSize: 14, // Increased from 12
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(int total, int pending, int approved) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          _buildStatItem('แปลง', total, AppColors.primary, null),
          _buildStatDivider(),
          _buildStatItem('รอตรวจ', pending, AppColors.warning, 'PENDING'),
          _buildStatDivider(),
          _buildStatItem('รับรอง', approved, AppColors.success, 'APPROVED'),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    int value,
    Color color,
    String? filterKey,
  ) {
    final isSelected = _selectedStatusFilter == filterKey;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: filterKey != null
              ? () => _toggleFilter(filterKey)
              : () => _toggleFilter(null),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$value',
                    style: GoogleFonts.prompt(
                      fontSize: 28, // Increased from 20
                      fontWeight: FontWeight.w800, // Maximized weight
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.prompt(
                    fontSize: 14, // Increased from 12
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600, // Increased weight
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }

  Widget _buildPlotListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('แปลงของฉัน'),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapDrawingScreen()),
              );
              _loadPlots();
            },
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: HeroIcon(
                HeroIcons.plus,
                color: Colors.white,
                size: 18,
                style: HeroIconStyle.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlots() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const HeroIcon(
              HeroIcons.map,
              size: 28,
              color: AppColors.primary,
              style: HeroIconStyle.outline,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'ยังไม่มีแปลงที่ลงทะเบียน',
            style: GoogleFonts.prompt(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'วาดแปลงบนแผนที่เพื่อเริ่มบันทึก GAP',
            style: GoogleFonts.prompt(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapDrawingScreen()),
              );
              _loadPlots();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const HeroIcon(
              HeroIcons.plus,
              size: 16,
              style: HeroIconStyle.outline,
            ),
            label: Text(
              'สร้างแปลงแรก',
              style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotsList(List<PlotModel> plots) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: plots.map((plot) => _buildPlotCard(plot)).toList(),
    );
  }

  Widget _buildPlotCard(PlotModel plot) {
    Color statusColor = AppColors.textSecondary;
    String statusLabel = 'รอดำเนินการ';

    if (plot.status == 'PENDING') {
      statusColor = AppColors.warning;
      statusLabel = 'รอตรวจสอบ';
    } else if (plot.status == 'APPROVED') {
      statusColor = AppColors.success;
      statusLabel = 'ผ่านรับรอง';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlotDetailScreen(plot: plot)),
            );
            if (result == true) _loadPlots();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _PlotMiniMap(plot: plot),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot.name,
                        style: GoogleFonts.prompt(
                          fontSize: 18, // Increased from 15
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${plot.areaRai?.toStringAsFixed(1) ?? "-"} ไร่ • ${plot.province ?? ""}',
                        style: GoogleFonts.prompt(
                          fontSize: 14, // Increased from 12
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.prompt(
                            fontSize: 12, // Increased from 11
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const HeroIcon(
                  HeroIcons.chevronRight,
                  color: AppColors.textTertiary,
                  size: 18,
                  style: HeroIconStyle.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const HeroIcon(
                    HeroIcons.bell,
                    color: AppColors.primary,
                    size: 22,
                    style: HeroIconStyle.outline,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'การแจ้งเตือน',
                    style: GoogleFonts.prompt(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return const SingleChildScrollView(
                      child: SkeletonListTile(count: 3, height: 72),
                    );
                  }
                  
                  final notifications = provider.notifications;
                  
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HeroIcon(
                            HeroIcons.bellSlash,
                            color: AppColors.textTertiary,
                            size: 40,
                            style: HeroIconStyle.outline,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'ยังไม่มีการแจ้งเตือน',
                            style: GoogleFonts.prompt(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? AppColors.surfaceVariant
                                : AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: HeroIcon(
                            HeroIcons.informationCircle,
                            color: n.isRead
                                ? AppColors.textTertiary
                                : AppColors.primary,
                            size: 18,
                            style: HeroIconStyle.outline,
                          ),
                        ),
                        title: Text(
                          n.title,
                          style: GoogleFonts.prompt(
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: n.message != null
                            ? Text(
                                n.message!,
                                style: GoogleFonts.prompt(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Text(
                          _formatTime(n.createdAt), // You might need a helper method or just use a simple string if time is string
                          style: GoogleFonts.prompt(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        onTap: () => context.read<NotificationProvider>().markAsRead(n.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays} วันที่แล้ว';
    if (diff.inHours > 0) return '${diff.inHours} ชม. ที่แล้ว';
    if (diff.inMinutes > 0) return '${diff.inMinutes} นาทีที่แล้ว';
    return 'เมื่อสักครู่';
  }

  void _showPlotSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'เลือกแปลงเพื่อกรอก GAP',
                    style: GoogleFonts.prompt(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const HeroIcon(
                      HeroIcons.xMark,
                      style: HeroIconStyle.outline,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<PlotModel>>(
                future: context.read<PlotService>().getMyPlots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SingleChildScrollView(
                      child: SkeletonListTile(count: 3, height: 80),
                    );
                  }
                  final plots = snapshot.data ?? [];
                  if (plots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HeroIcon(
                            HeroIcons.map,
                            size: 40,
                            color: AppColors.textTertiary,
                            style: HeroIconStyle.outline,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'คุณยังไม่มีแปลง',
                            style: GoogleFonts.prompt(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MapDrawingScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'ลงทะเบียนแปลงใหม่',
                              style: GoogleFonts.prompt(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: plots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final plot = plots[index];
                      return Material(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GapMainScreen(plotId: plot.id ?? ''),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const HeroIcon(
                                    HeroIcons.documentText,
                                    color: AppColors.primary,
                                    size: 20,
                                    style: HeroIconStyle.outline,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plot.name,
                                        style: GoogleFonts.prompt(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${plot.species ?? 'ไม่ระบุพืช'} • ${plot.areaRai ?? 0} ไร่',
                                        style: GoogleFonts.prompt(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const HeroIcon(
                                  HeroIcons.chevronRight,
                                  color: AppColors.textTertiary,
                                  size: 18,
                                  style: HeroIconStyle.outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ══════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    var status = await Permission.photos.status;
    if (status.isDenied) {
      await Permission.photos.request();
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _imageFile = File(image.path));
      }
    } catch (e) {
      // Silent failure - image picking is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _buildProfileHeader(),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildMenuSection(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        return Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Center(
                            child: Text(
                              user?.firstName?.substring(0, 1) ?? 'U',
                              style: GoogleFonts.prompt(
                                color: AppColors.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const HeroIcon(
                        HeroIcons.camera,
                        color: Colors.white,
                        size: 14,
                        style: HeroIconStyle.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user != null ? '${user.firstName} ${user.lastName}' : 'ผู้ใช้งาน',
              style: GoogleFonts.prompt(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.phone ?? '',
              style: GoogleFonts.prompt(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuContainer([
          _buildMenuItem(
            icon: HeroIcons.user,
            title: 'ข้อมูลส่วนตัว',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
            ),
          ),
          const Divider(height: 1, indent: 54),
          _buildMenuItem(
            icon: HeroIcons.map,
            title: 'แปลงของฉัน',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyPlotsMapScreen()),
            ),
          ),
          const Divider(height: 1, indent: 54),
          _buildMenuItem(
            icon: HeroIcons.buildingOffice2,
            title: 'ติดต่อเรา',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactScreen()),
            ),
          ),
          const Divider(height: 1, indent: 54),
          _buildMenuItem(
            icon: HeroIcons.clock,
            title: 'ประวัติการยื่นขอ',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestHistoryScreen()),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _buildMenuContainer([
          _buildMenuItem(
            icon: HeroIcons.cog6Tooth,
            title: 'ตั้งค่า',
            color: AppColors.textSecondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        _buildMenuContainer([
          _buildMenuItem(
            icon: HeroIcons.arrowRightOnRectangle,
            title: 'ออกจากระบบ',
            color: AppColors.error,
            showChevron: false,
            onTap: () => _showLogoutDialog(context),
          ),
        ]),
        const SizedBox(height: 28),

        Text(
          'Version 1.0.0',
          style: GoogleFonts.prompt(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2024 Taptom. All rights reserved.',
          style: GoogleFonts.prompt(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required HeroIcons icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: HeroIcon(
                  icon,
                  color: color,
                  size: 20,
                  style: HeroIconStyle.outline,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (showChevron)
                const HeroIcon(
                  HeroIcons.chevronRight,
                  color: AppColors.textTertiary,
                  size: 18,
                  style: HeroIconStyle.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ออกจากระบบ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('ยืนยัน', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MINI MAP WIDGET
// ══════════════════════════════════════════════════════════════
class _PlotMiniMap extends StatefulWidget {
  final PlotModel plot;
  const _PlotMiniMap({required this.plot});

  @override
  State<_PlotMiniMap> createState() => _PlotMiniMapState();
}

class _PlotMiniMapState extends State<_PlotMiniMap> {
  MaplibreMapController? _controller;
  static String get _styleUrl =>
      'https://api.maptiler.com/maps/hybrid/style.json?key=${Env.mapTilerApiKey}';

  @override
  Widget build(BuildContext context) {
    final boundary = widget.plot.boundary;
    if (boundary.isEmpty) {
      return Container(
        color: AppColors.primary.withOpacity(0.08),
        child: const Center(
          child: HeroIcon(
            HeroIcons.map,
            color: AppColors.primary,
            size: 24,
            style: HeroIconStyle.outline,
          ),
        ),
      );
    }

    double sumLat = 0, sumLng = 0;
    for (final point in boundary) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    final centerLat = sumLat / boundary.length;
    final centerLng = sumLng / boundary.length;

    return MaplibreMap(
      styleString: _styleUrl,
      initialCameraPosition: CameraPosition(
        target: LatLng(centerLat, centerLng),
        zoom: 15,
      ),
      compassEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onMapCreated: (controller) {
        _controller = controller;
      },
      onStyleLoadedCallback: () => _addPolygon(),
    );
  }

  void _addPolygon() {
    if (_controller == null) return;

    final boundary = widget.plot.boundary;
    if (boundary.isEmpty) return;

    _controller!.addFill(
      FillOptions(geometry: [boundary], fillColor: '#2D7A4F', fillOpacity: 0.3),
    );

    _controller!.addLine(
      LineOptions(geometry: boundary, lineColor: '#2D7A4F', lineWidth: 2),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
