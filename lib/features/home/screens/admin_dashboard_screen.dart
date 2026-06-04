import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pdpa_content.dart'; // NEW
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/nature_background.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../admin/screens/user_management_screen.dart';
import '../../admin/screens/admin_plots_map_screen.dart';
import '../../admin/screens/audit_log_screen.dart';

import '../../admin/widgets/user_detail_sheet.dart';
import '../../admin/providers/admin_state_provider.dart';
import '../../../core/utils/admin_error_handler.dart';
import '../../admin/widgets/admin_confirmation_dialog.dart';
import '../../profile/screens/personal_info_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../shared/screens/support_ticket_screen.dart';
import '../../admin/widgets/gap_analytics_card.dart';
import '../../admin/widgets/user_trends_chart.dart';
import '../../notification/screens/notification_list_screen.dart';
import '../../notifications/providers/notification_provider.dart'; // Add this line
import '../../../core/widgets/notification_icon.dart'; // Added
import '../../admin/screens/edit_profile_screen.dart';
import '../../admin/screens/change_pin_screen.dart';
import '../../settings/screens/content_display_screen.dart';
import '../../settings/settings_provider.dart';
import '../../../core/services/feedback_service.dart';
import '../../admin/screens/create_plot_for_user_screen.dart';
import '../../admin/screens/admin_plot_list_screen.dart';
import '../../../core/services/cache_service.dart';


/// Admin Dashboard with Bottom Navigation - เหมือน User Dashboard
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const AdminHomeScreen();
      case 1:
        return const AdminPlotsMapScreen(isMainTab: true);
      case 2:
        return const UserManagementScreen(isEmbedded: true);
      case 3:
        return const AdminProfileScreen();
      default:
        return const AdminHomeScreen();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
          child: GNav(
            rippleColor: Colors.grey[200]!,
            hoverColor: Colors.grey[100]!,
            gap: 8,
            // Admin uses Orange accent to distinguish from User (Green)
            activeColor: AppColors.adminPrimary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(milliseconds: 300),
            tabBackgroundColor: AppColors.adminPrimary.withValues(alpha: 0.1),
            color: Colors.grey[500],
            tabs: const [
              GButton(icon: Icons.dashboard_rounded, text: 'หน้าหลัก'),
              GButton(icon: Icons.map_rounded, text: 'แผนที่'),
              GButton(icon: Icons.people_rounded, text: 'สมาชิก'),
              GButton(icon: Icons.person_rounded, text: 'โปรไฟล์'),
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

// ==================== ADMIN HOME SCREEN ====================
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      context.read<NotificationProvider>().startPolling();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<AdminStateProvider>();
    await Future.wait([
      provider.loadStats(),
      provider.loadUsers(status: 'PENDING'),
      provider.loadAnalytics(), // NEW
    ]);
  }

  Future<void> _approveUser(UserModel user) async {
    // Show confirmation dialog first
    final confirmed = await AdminConfirmationDialog.showApproval(
      context,
      user: user,
    );

    if (confirmed != true) return;

    try {
      await context.read<AdminStateProvider>().approveUser(user.id);

      if (!mounted) return;
      AdminErrorHandler.showSuccess(
        context,
        message: 'อนุมัติ ${user.fullName} สำเร็จ',
        detail: 'สมาชิกสามารถเข้าใช้งานระบบได้แล้ว',
      );
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(
        context,
        e,
        operation: 'อนุมัติสมาชิก',
        onRetry: () => _approveUser(user),
      );
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    // Show rejection dialog with reason input
    final reason = await AdminConfirmationDialog.showRejection(
      context,
      user: user,
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await context.read<AdminStateProvider>().rejectUser(user.id, reason);

      if (!mounted) return;
      AdminErrorHandler.showWarning(
        context,
        message: 'ปฏิเสธ ${user.fullName} สำเร็จ',
        detail: 'ส่งการแจ้งเตือนไปยังผู้สมัครแล้ว',
      );
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(
        context,
        e,
        operation: 'ปฏิเสธสมาชิก',
        onRetry: () => _rejectUser(user),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HeroIcon(
                HeroIcons.xCircle,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ปฏิเสธคำขอ',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'กรุณาระบุเหตุผลในการปฏิเสธ เพื่อแจ้งให้ผู้สมัครทราบ',
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'เช่น ข้อมูลไม่ครบถ้วน, เอกสารไม่ถูกต้อง...',
                  hintStyle: GoogleFonts.prompt(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 4,
                style: GoogleFonts.prompt(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาระบุเหตุผลในการปฏิเสธ';
                  }
                  if (value.trim().length < 10) {
                    return 'เหตุผลต้องมีอย่างน้อย 10 ตัวอักษร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const HeroIcon(
                      HeroIcons.informationCircle,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เหตุผลนี้จะถูกส่งเป็นการแจ้งเตือนไปยังผู้สมัคร',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            icon: const HeroIcon(
              HeroIcons.xMark,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              'ปฏิเสธ',
              style: GoogleFonts.prompt(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final provider = context.watch<AdminStateProvider>();
    final authProvider = context.watch<AuthProvider>();

    // User info
    final user = authProvider.user;
    final isSuperAdmin = user?.role == UserRole.superAdmin;
    final rolePrimary = isSuperAdmin
        ? AppColors.superAdminPrimary
        : AppColors.adminPrimary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey base
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: Stack(
          children: [
            // Curved Header Background (No Circles)
            // Twisted Curved Background (Moved to Bottom)
            // Twisted Curved Background (Bottom Design)
            // Full Screen Background Image (Faint)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  'assets/images/Chat.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // White Overlay Gradient for readability (Optional smoothness)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.9), // Fade top to white
                      Colors.white.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: rolePrimary,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 1. TOP BAR
                      _buildTopBar(isSuperAdmin),
                      const SizedBox(height: 24),

                      // 2. PROFILE SECTION
                      _buildProfileSection(user, isSuperAdmin),
                      const SizedBox(height: 32),

                      // 3. STATS ROW
                      _buildStatsRow(provider.stats, provider.pendingUsers.length, rolePrimary),
                      const SizedBox(height: 32),

                      // 4. QUICK SHORTCUTS
                      _buildSectionLabel('เมนูลัด', Colors.black87),
                      const SizedBox(height: 16),
                      _buildNewQuickShortcuts(rolePrimary, isSuperAdmin),
                      const SizedBox(height: 32),

                      // 5. MEMBER INSIGHTS
                      _buildSectionLabel('ข้อมูลเชิงลึกสมาชิก', Colors.black87),
                      const SizedBox(height: 16),
                      if (provider.userTrends.isNotEmpty) ...[
                         UserTrendsChart(data: provider.userTrends),
                         const SizedBox(height: 100),
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

  Widget _buildTopBar(bool isSuperAdmin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Admin Icon
            Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: AppColors.adminPrimary.withOpacity(0.12), // Visible glass fill
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.adminPrimary.withOpacity(0.4), width: 1.5), // Strong glass border
               ),
               child: const HeroIcon(
                 HeroIcons.shieldCheck, 
                 color: AppColors.adminPrimary, 
                 size: 24
                ),
            ),
            const SizedBox(width: 12),
            Text(
              'หัวหน้ารัฐวิสาหกิจชุมชน',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            if (!settings.notificationsEnabled) return const SizedBox.shrink();
            
            if (!settings.notificationsEnabled) return const SizedBox.shrink();
            
            return NotificationIcon(color: AppColors.primary);
          }
        ),
      ],

    );
  }

  Widget _buildProfileSection(UserModel? user, bool isSuperAdmin) {
    final firstName = user?.firstName ?? 'Admin';
    final lastName = user?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    // Load image if available, else use initials.
    final initial = firstName.isNotEmpty ? firstName[0] : 'A';
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;

    return Row(
      children: [
        // Large Avatar
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasPhoto ? null : AppColors.adminPrimary.withOpacity(0.1),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            image: hasPhoto
                ? DecorationImage(
                    image: NetworkImage(user!.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: hasPhoto
              ? null
              : Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.prompt(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullName.isNotEmpty ? fullName : 'ผู้ดูแลระบบ',
              style: GoogleFonts.prompt(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'ยินดีต้อนรับสู่ศูนย์ควบคุม',
              style: GoogleFonts.prompt(
                fontSize: 14,
                color: AppColors.primary, 
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats, int pendingCount, Color rolePrimary) {
    return Row(
      children: [
        _buildStatCard(
          'สมาชิก\nทั้งหมด',
          '${stats['total'] ?? 0}',
          Colors.blueGrey,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'รอการ\nอนุมัติ',
          '$pendingCount',
          Colors.amber,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'ยืนยัน\nแล้ว',
          '${stats['approved'] ?? 0}',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5), // Visible colored border
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Colored Indicator Bar
            Container(
              width: 5,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151), // Dark gray, very readable
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count,
                    style: GoogleFonts.prompt(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827), // Near-black
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewQuickShortcuts(Color rolePrimary, bool isSuperAdmin) {
    return Column(
      children: [
        Row(
           children: [
             Expanded(
               child: _buildShortcutCard(
                 icon: HeroIcons.map,
                 label: 'แก้ไขแปลงผู้ใช้',
                 color: Colors.green[700]!, // Darker Green
                 onTap: () {
                    Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => const AdminPlotsMapScreen(userId: null),
                     ),
                   );
                 },
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _buildShortcutCard(
                 icon: HeroIcons.clipboardDocumentList,
                 label: 'GAP',
                 color: Colors.teal, // Slight variation but still green-tone
                 onTap: () {
                    Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (_) => UserManagementScreen(
                           onUserSelected: (user) {
                             Navigator.pop(context); // Close User Picker
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (_) => AdminPlotListScreen(
                                   userId: user.id,
                                   userName: user.fullName,
                                 ),
                               ),
                             );
                           },
                         ),
                       ),
                     );
                 },
               ),
             ),
           ],
         ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildShortcutCard(
                icon: HeroIcons.checkBadge,
                label: 'แปลงที่อนุมัติ',
                color: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPlotListScreen(
                        initialStatusFilter: 'APPROVED',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildShortcutCard(
                icon: HeroIcons.chatBubbleLeftRight,
                label: 'ติดต่อผู้ดูแลระบบ', 
                color: const Color(0xFF2E7D32), // Forest Green
                onTap: () {
                   context.push('/admin/messages');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required HeroIcons icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5), // Visible colored glass border
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12), // Clearly visible glass fill
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4), width: 1.5), // Strong glass border
              ),
              child: HeroIcon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937), // Very dark, high contrast
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideShortcutCard({
    required HeroIcons icon,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.deepOrange.withOpacity(0.2), width: 1.5), // Visible colored border
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12), // Clearly visible glass fill
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5), // Strong glass border
              ),
              child: const HeroIcon(
                HeroIcons.map,
                color: Colors.deepOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937), // Very dark, clear
                    ),
                  ),
                  Text(
                    subLabel,
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: const Color(0xFF4B5563), // Dark gray subtitle
                    ),
                  ),
                ],
              ),
            ),
            const HeroIcon(
              HeroIcons.chevronRight,
              color: Colors.deepOrange,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required HeroIcons icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.10),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5), // Visible colored border
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12), // Clearly visible glass fill
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5), // Strong glass border
              ),
              child: HeroIcon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937), // Very dark, clear
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            HeroIcon(
              HeroIcons.chevronRight,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ADMIN PROFILE SCREEN ====================
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _isClearingCache = false;

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const HeroIcon(
                HeroIcons.exclamationTriangle,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ล้างแคช',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการล้างข้อมูลแคชของแอปหรือไม่?',
              style: GoogleFonts.prompt(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const HeroIcon(
                    HeroIcons.informationCircle,
                    color: AppColors.info,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การล้างแคชจะไม่ลบข้อมูลสำคัญของคุณ',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isClearingCache
                ? null
                : () => Navigator.of(dialogContext).pop(),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _isClearingCache
                ? null
                : () async {
                    setState(() => _isClearingCache = true);

                    // Real cache clearing
                    await CacheService().clearAllCache();
                    // Optional delay for UI feedback
                    await Future.delayed(const Duration(milliseconds: 500));

                    if (!mounted) return;

                    setState(() => _isClearingCache = false);
                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ล้างแคชเรียบร้อยแล้ว')),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isClearingCache
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'ล้างแคช',
                    style: GoogleFonts.prompt(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              'ออกจากระบบ',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'ออกจากระบบ',
              style: GoogleFonts.prompt(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final user = authProvider.user;
    final isSuperAdmin = user?.role == UserRole.superAdmin;
    final rolePrimary =
        isSuperAdmin ? AppColors.superAdminPrimary : AppColors.adminPrimary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // 1. Background Image & Overlay (Consistent with Dashboard)
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/Chat.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // 2. Top Bar
                  _buildTopBar(),
                  const SizedBox(height: 24),

                  // 3. User Profile
                  _buildUserProfile(user, isSuperAdmin, rolePrimary),
                  const SizedBox(height: 32),

                  // 4. Settings Sections
                  _buildSectionLabel('บัญชี'),
                  _buildMenuItem(
                    context,
                    icon: HeroIcons.userCircle,
                    title: 'แก้ไขข้อมูลส่วนตัว',
                    subtitle: 'ชื่อ, ที่อยู่, เบอร์โทรศัพท์',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: HeroIcons.lockClosed,
                    title: 'เปลี่ยนรหัส PIN',
                    subtitle: 'รหัสเข้าใช้งาน 6 หลัก',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePinScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('การตั้งค่าทั่วไป'),
                  _buildSwitchItem(
                    title: 'การแจ้งเตือน',
                    value: settings.notificationsEnabled,
                    onChanged: (val) async {
                      final success = await settings.toggleNotifications(val);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('กรุณาเปิดสิทธิ์การแจ้งเตือนในตั้งค่าอุปกรณ์'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    activeColor: rolePrimary,
                  ),
                  _buildMenuItem(
                    context,
                    icon: HeroIcons.trash,
                    title: 'ล้างแคช',
                    subtitle: 'ลบข้อมูลชั่วคราว',
                    onTap: _showClearCacheDialog,
                    isDestructive: true,
                    destructiveColor: Colors.orange,
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('ข้อมูลและกฎหมาย'),
                  _buildMenuItem(
                    context,
                    icon: HeroIcons.documentText,
                    title: 'ข้อกำหนดและเงื่อนไข',
                    subtitle: 'อ่านข้อกำหนด',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContentDisplayScreen(
                            title: 'ข้อกำหนดและเงื่อนไข',
                            content: 'เนื้อหาข้อกำหนด...',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: HeroIcons.shieldCheck,
                    title: 'นโยบายความเป็นส่วนตัว',
                    subtitle: 'PDPA',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContentDisplayScreen(
                            title: PdpaContent.title,
                            content:
                                '${PdpaContent.fullContent}\n\n${PdpaContent.references}',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('อื่นๆ'),
                  _buildMenuItem(
                    context,
                    icon: HeroIcons.lifebuoy,
                    title: 'ช่วยเหลือ',
                    subtitle: 'ติดต่อทีมงาน',
                    onTap: () {
                      context.push('/admin/support');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: HeroIcons.arrowRightOnRectangle,
                    title: 'ออกจากระบบ',
                    subtitle: 'ลงชื่อออก',
                    onTap: _handleLogout,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      'TAPTOM ADMIN v${settings.version}',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom spacing for FAB/Nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.adminPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const HeroIcon(
            HeroIcons.cog6Tooth,
            color: AppColors.adminPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'การตั้งค่า',
          style: GoogleFonts.prompt(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(
      UserModel? user, bool isSuperAdmin, Color rolePrimary) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            image: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(user.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
              ? Center(
                  child: Text(
                    user?.firstName.isNotEmpty == true
                        ? user!.firstName[0]
                        : 'A',
                    style: GoogleFonts.prompt(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: rolePrimary,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
              style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: rolePrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
                style: GoogleFonts.prompt(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: rolePrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.prompt(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required HeroIcons icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    Color? destructiveColor,
  }) {
    final color = isDestructive ? (destructiveColor ?? Colors.red) : Colors.grey[700];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? color!.withOpacity(0.1)
                        : AppColors.adminPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HeroIcon(
                    icon,
                    color: isDestructive ? color : AppColors.adminPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? color : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[300],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HeroIcon(
                HeroIcons.bell,
                color: activeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor,
            ),
          ],
        ),
      ),
    );
  }
}