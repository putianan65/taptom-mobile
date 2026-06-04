import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import 'change_pin_screen.dart';
import 'edit_profile_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text('ออกจากระบบ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?\nคุณจะต้องเข้าสู่ระบบใหม่อีกครั้ง',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('ออกจากระบบ', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await context.read<AuthProvider>().signOut();
        if (mounted) {
           context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      appBar: AppBar(
        title: Text('ตั้งค่า', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(user),
          const SizedBox(height: 24),
          
          _buildSectionHeader('บัญชี'),
          _buildListTile(
            icon: HeroIcons.user,
            title: 'แก้ไขข้อมูลส่วนตัว',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          
          const Divider(height: 32),
          
          _buildSectionHeader('ความปลอดภัย'),
          _buildListTile(
            icon: HeroIcons.lockClosed,
            title: 'เปลี่ยนรหัส PIN',
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const ChangePinScreen()),
            ),
          ),
          
          const Divider(height: 32),
          
          _buildListTile(
            icon: HeroIcons.arrowRightOnRectangle, // Logout icon
            title: 'ออกจากระบบ',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: _handleLogout,
            showChevron: false,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel? user) {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 35, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user?.firstName} ${user?.lastName}',
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? '',
                  style: GoogleFonts.prompt(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.role.name.toUpperCase() ?? 'USER',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.prompt(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required HeroIcons icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HeroIcon(
                   icon, 
                   color: iconColor ?? AppColors.primary, 
                   size: 24,
                   style: HeroIconStyle.outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? Colors.grey[800],
                  ),
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
