import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/super_admin_service.dart';
import '../widgets/luxury_dialog.dart'; // Added

class AdminManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const AdminManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<dynamic> _admins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use SuperAdminService
      final service = context.read<SuperAdminService>();
      final admins = await service.getAdminList();

      if (mounted) {
        setState(() {
          _admins = admins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAdmin(String adminId, String adminName) async {
    final confirmed = await LuxuryDialog.show(
      context,
      title: 'ลบ Admin',
      content: 'คุณแน่ใจหรือไม่ที่จะลบ $adminName?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
      icon: HeroIcons.trash,
      accentColor: AppColors.error,
      confirmText: 'ลบข้อมูล',
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      final service = context.read<SuperAdminService>();
      await service.deleteAdmin(adminId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบ Admin สำเร็จ', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.success,
        ),
      );

      _loadAdmins(); // Reload list
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LuxuryTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            if (!widget.isEmbedded)
              _buildAppBar(context),
            if (widget.isEmbedded)
              _buildEmbeddedHeader(),
            Expanded(
              child: Stack(
                children: [
                  _buildBody(),
                  // Floating bottom create button
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 100,
                    child: GestureDetector(
                      onTap: () {
                        context.push('/super-admin/admins/create').then((_) => _loadAdmins());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: LuxuryTheme.purpleNeon.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const HeroIcon(HeroIcons.plus, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'เพิ่ม Admin ใหม่',
                              style: GoogleFonts.prompt(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildAppBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildGlassIconButton(
              icon: HeroIcons.arrowLeft,
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Text(
                'จัดการ Admin',
                style: GoogleFonts.prompt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 44), // Placeholder to keep title centered
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Text(
        'จัดการ Admin',
        style: GoogleFonts.prompt(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required HeroIcons icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HeroIcon(
              HeroIcons.exclamationTriangle,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.prompt(fontSize: 16, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAdmins,
              icon: const HeroIcon(HeroIcons.arrowPath, size: 20),
              label: Text('ลองใหม่', style: GoogleFonts.prompt()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              HeroIcons.userGroup,
              size: 64,
              color: LuxuryTheme.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มี Admin',
              style: GoogleFonts.prompt(
                fontSize: 18,
                color: LuxuryTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdmins,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _admins.length,
        itemBuilder: (context, index) {
          final admin = _admins[index];
          return _buildAdminCard(admin);
        },
      ),
    );
  }

  Widget _buildAdminCard(dynamic admin) {
    final String id = admin['id'] ?? '';
    final String firstName = admin['firstName'] ?? '';
    final String lastName = admin['lastName'] ?? '';
    final String phone = admin['phone'] ?? '';
    final int managedUsersCount = admin['managedUsersCount'] ?? 0;
    final String fullName = '$firstName $lastName';
    final String? province = admin['province'];
    final String? district = admin['district'];

    String locationStr = '';
     if (district != null && district.isNotEmpty) {
      locationStr = 'อ.$district';
      if (province != null && province.isNotEmpty)
        locationStr += ' จ.$province';
    } else if (province != null && province.isNotEmpty) {
      locationStr = 'จ.$province';
    }

    const accentColor = LuxuryTheme.cyanNeon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LuxuryTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LuxuryTheme.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push('/super-admin/admins/detail', extra: admin).then((_) => _loadAdmins());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                      child: Center(
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            phone,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: LuxuryTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    HeroIcon(
                      HeroIcons.chevronRight,
                      size: 20,
                      color: LuxuryTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const HeroIcon(HeroIcons.trash, color: Color(0xFFFF1744)),
                      onPressed: () => _deleteAdmin(id, fullName),
                    ),
                  ],
                ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                      _buildTag(HeroIcons.users, '$managedUsersCount users', LuxuryTheme.purpleNeon),
                      if(locationStr.isNotEmpty) ...[
                         const SizedBox(width: 8),
                         _buildTag(HeroIcons.mapPin, locationStr, LuxuryTheme.goldNeon),
                      ]
                   ],
                 )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTag(HeroIcons icon, String text, Color color) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
       decoration: BoxDecoration(
         color: color.withOpacity(0.1),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: color.withOpacity(0.3)),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           HeroIcon(icon, size: 14, color: color),
           const SizedBox(width: 6),
           Text(
             text,
              style: GoogleFonts.prompt(fontSize: 12, color: color, fontWeight: FontWeight.normal),
           )
         ],
       ),
     );
  }
}
