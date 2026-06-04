import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart';

/// Admin List Screen (SUPER_ADMIN Only)
/// Display all admins with their managed users count
class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
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
      final adminService = context.read<AdminService>();
      final admins = await adminService.getAdminList();

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ลบ Admin',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ที่จะลบ $adminName?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'ลบ',
              style: GoogleFonts.prompt(color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminService = context.read<AdminService>();
      await adminService.deleteAdmin(adminId);

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'จัดการ Admin',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const HeroIcon(HeroIcons.plus, color: AppColors.superAdminPrimary),
            onPressed: () {
              context.push('/admin/create').then((_) => _loadAdmins());
            },
            tooltip: 'สร้าง Admin ใหม่',
          ),
        ],
      ),
      body: _buildBody(),
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
            const HeroIcon(
              HeroIcons.userGroup,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มี Admin',
              style: GoogleFonts.prompt(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                context.push('/admin/create').then((_) => _loadAdmins());
              },
              icon: const HeroIcon(HeroIcons.plus, size: 20),
              label: Text('สร้าง Admin ใหม่', style: GoogleFonts.prompt()),
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

    // Location info
    final String? province = admin['province'];
    final String? district = admin['district'];
    final String? subDistrict = admin['subDistrict'];

    // Build location string
    String locationStr = '';
    if (subDistrict != null && subDistrict.isNotEmpty) {
      locationStr = 'ต.$subDistrict';
      if (district != null && district.isNotEmpty)
        locationStr += ' อ.$district';
      if (province != null && province.isNotEmpty)
        locationStr += ' จ.$province';
    } else if (district != null && district.isNotEmpty) {
      locationStr = 'อ.$district';
      if (province != null && province.isNotEmpty)
        locationStr += ' จ.$province';
    } else if (province != null && province.isNotEmpty) {
      locationStr = 'จ.$province';
    }

    // Super Admin uses Red accent for visual identity
    const accentColor = AppColors.superAdminPrimary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                      style: GoogleFonts.prompt(
                        fontSize: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.phone,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: GoogleFonts.prompt(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const HeroIcon(HeroIcons.trash, color: AppColors.error),
                  onPressed: () => _deleteAdmin(id, fullName),
                  tooltip: 'ลบ Admin',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroIcon(
                        HeroIcons.users,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ดูแล $managedUsersCount คน',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (locationStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HeroIcon(
                            HeroIcons.mapPin,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              locationStr,
                              style: GoogleFonts.prompt(
                                fontSize: 12,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
