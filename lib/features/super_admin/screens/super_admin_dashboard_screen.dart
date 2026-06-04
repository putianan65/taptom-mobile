import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/super_admin_service.dart';
import '../../auth/auth_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../../admin/screens/user_management_screen.dart';
import '../../admin/screens/admin_plots_map_screen.dart';
import '../../admin/widgets/user_trends_chart.dart'; // NEW
import '../widgets/gap_status_pie_chart.dart'; // NEW
import '../../../data/models/analytics_model.dart'; // NEW
import '../../../data/models/user_model.dart'; // Added
import 'admin_management_screen.dart';
import 'system_logs_screen.dart'; 
import '../../admin/screens/edit_profile_screen.dart';
import '../../notifications/providers/notification_provider.dart'; // NEW
import '../../../core/widgets/notification_icon.dart'; // Added
import '../widgets/luxury_dialog.dart'; // Added

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LuxuryTheme.backgroundGradient, // Midnight Blue Background
        ),
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentPage() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const SuperAdminHomeScreen(),
        const UserManagementScreen(isEmbedded: true),
        const AdminPlotsMapScreen(isMainTab: true), 
        const AdminManagementScreen(isEmbedded: true),
        const SuperAdminMenuScreen(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.midnightBlue.withOpacity(0.9), // Dark transparent
        border: Border(top: BorderSide(color: LuxuryTheme.glassBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12),
          child: GNav(
            rippleColor: Colors.white.withOpacity(0.1),
            hoverColor: Colors.white.withOpacity(0.1),
            gap: 6,
            activeColor: LuxuryTheme.cyanNeon, // Cyan Active
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            duration: const Duration(milliseconds: 300),
            tabBackgroundColor: LuxuryTheme.cyanNeon.withOpacity(0.15),
            color: Colors.grey[400], // Inactive color
            tabs: const [
              GButton(icon: Icons.dashboard_rounded, text: 'หน้าหลัก'),
              GButton(icon: Icons.people_rounded, text: 'ผู้ใช้'),
              GButton(icon: Icons.map_rounded, text: 'แผนที่'),
              GButton(icon: Icons.shield, text: 'ผู้ดูแล'),
              GButton(icon: Icons.menu_rounded, text: 'เมนู'),
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

// ==================== HOME SCREEN (Luxury Redesign) ====================

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  Map<String, dynamic> _stats = {};
  List<UserTrendsData> _userTrends = [];
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().startPolling();
    });
  }

  Future<void> _loadStats() async {
    try {
      final service = context.read<SuperAdminService>();
      final results = await Future.wait([
        service.getSystemStats(),
        service.getRegistrationTrends(),
      ]);
      
      final stats = results[0] as Map<String, dynamic>;
      final rawTrends = results[1] as List<dynamic>;

      final trends = rawTrends.map((e) => UserTrendsData.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _stats = stats;
          _userTrends = trends;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.transparent, // Use container gradient
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              _buildHeader(user),

              const SizedBox(height: 32),

              // Glass Stats
              _buildQuickStats(),
              
              const SizedBox(height: 32),
              
              // Charts Section
              if (!_isLoadingStats) ...[
                Text(
                  'ภาพรวมระบบ', // Thai title
                  style: GoogleFonts.prompt( // Modern Font for Thai
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: LuxuryTheme.cyanNeon,
                  ),
                ),
                const SizedBox(height: 16),
                // User Trends Chart (Glass)
                UserTrendsChart(data: _userTrends, isDarkMode: true),
                
                const SizedBox(height: 24),
                
                // Status Pie Chart (Glass)
                GapStatusPieChart(
                  approvedCount: (_stats['totalUsers'] as int? ?? 0) - (_stats['pendingUsers'] as int? ?? 0),
                  pendingCount: _stats['pendingUsers'] as int? ?? 0,
                  title: 'สัดส่วนผู้ใช้งาน', // Thai title
                ),
              ] else 
                const Center(child: CircularProgressIndicator(color: LuxuryTheme.cyanNeon)),

              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Profile Picture
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: LuxuryTheme.cyanNeon.withOpacity(0.5), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: LuxuryTheme.midnightBlue,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.person, color: LuxuryTheme.cyanNeon, size: 24)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Name and Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผู้ควบคุมระบบสูงสุด',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: LuxuryTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim().isEmpty 
                          ? 'Super Admin' 
                          : '${user?.firstName} ${user?.lastName}',
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
          Row(
            children: [
               const NotificationIcon(color: Colors.white),
               const SizedBox(width: 12),
               _buildGlassIconButton(
                 icon: HeroIcons.chatBubbleLeftRight,
                 color: LuxuryTheme.cyanNeon, 
                 onPressed: () => context.push('/admin/messages'),
               ),
            ],
          ),
      ],
    );
  }

  Widget _buildGlassIconButton({required HeroIcons icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: LuxuryTheme.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LuxuryTheme.glassBorder, width: 1),
        ),
        child: HeroIcon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildQuickStats() {
    return _buildGlassCard(
      child: _isLoadingStats
          ? const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(color: LuxuryTheme.cyanNeon),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'ผู้ใช้งานทั้งหมด',
                        '${_stats['totalUsers'] ?? 0}',
                        HeroIcons.users,
                        LuxuryTheme.cyanNeon,
                      ),
                    ),
                    Container(width: 1, height: 40, color: LuxuryTheme.glassBorder),
                    Expanded(
                      child: _buildStatItem(
                        'ผู้ดูแลระบบ',
                        '${_stats['totalAdmins'] ?? 0}',
                        HeroIcons.shieldCheck,
                        LuxuryTheme.purpleNeon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: LuxuryTheme.glassBorder, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'แปลงเกษตร',
                        '${_stats['totalPlots'] ?? 0}',
                        HeroIcons.map,
                        LuxuryTheme.emeraldNeon,
                      ),
                    ),
                    Container(width: 1, height: 40, color: LuxuryTheme.glassBorder),
                    Expanded(
                      child: _buildStatItem(
                        'รออนุมัติ',
                        '${_stats['pendingUsers'] ?? 0}',
                        HeroIcons.clock,
                        LuxuryTheme.goldNeon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(
      String label, String value, HeroIcons icon, Color color) {
    return Column(
      children: [
        // Glowing Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: HeroIcon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.prompt(
            fontSize: 10,
            letterSpacing: 0.5,
            color: LuxuryTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LuxuryTheme.glassSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LuxuryTheme.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ==================== MENU SCREEN (Luxury Redesign) ====================

class SuperAdminMenuScreen extends StatelessWidget {
  const SuperAdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for gradient
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Header
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow removed

                        // Profile Image
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: LuxuryTheme.cyanNeon, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: user?.photoUrl != null
                                ? NetworkImage(user!.photoUrl!)
                                : null,
                            child: user?.photoUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0, // Adjusted position
                          child: GestureDetector(
                             onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen()),
                              ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: LuxuryTheme.cyanNeon,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.black, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim().isEmpty 
                          ? 'Super Admin' 
                          : '${user?.firstName} ${user?.lastName}',
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: LuxuryTheme.goldNeon),
                        borderRadius: BorderRadius.circular(20),
                        color: LuxuryTheme.goldNeon.withOpacity(0.1),
                      ),
                      child: Text(
                        'ผู้ดูแลสูงสุด',
                        style: GoogleFonts.prompt(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: LuxuryTheme.goldNeon,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(
                    context,
                    title: 'แก้ไขโปรไฟล์',
                    icon: HeroIcons.userCircle,
                    color: LuxuryTheme.cyanNeon,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'บันทึกกิจกรรม',
                    icon: HeroIcons.clipboardDocumentList,
                    color: LuxuryTheme.goldNeon,
                    onTap: () => context.push('/super-admin/logs'),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'ตั้งค่าระบบ',
                    icon: HeroIcons.cog6Tooth,
                    color: Colors.white,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'ออกจากระบบ',
                    icon: HeroIcons.arrowRightOnRectangle,
                    color: LuxuryTheme.purpleNeon,
                    isDestructive: true,
                    onTap: () async {
                      final confirmed = await LuxuryDialog.show(
                        context,
                        title: 'ออกจากระบบ',
                        content: 'คุณต้องการออกจากระบบใช่หรือไม่?',
                        icon: HeroIcons.arrowRightOnRectangle,
                        accentColor: LuxuryTheme.purpleNeon,
                        confirmText: 'ออกจากระบบ',
                        isDestructive: true,
                      );
                      
                      if (confirmed == true && context.mounted) {
                        context.read<AuthProvider>().signOut();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required HeroIcons icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: LuxuryTheme.glassSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LuxuryTheme.glassBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              highlightColor: color.withOpacity(0.1),
              splashColor: color.withOpacity(0.2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(icon, size: 32, color: color),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
