import 'dart:async';
import '../../super_admin/widgets/luxury_dialog.dart'; // Added
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/super_admin_service.dart';
import '../../../core/widgets/nature_background.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../widgets/user_list_item.dart';
import '../providers/admin_state_provider.dart';
import '../../../core/utils/admin_error_handler.dart';
import '../widgets/admin_confirmation_dialog.dart';
import 'admin_plot_list_screen.dart';

/// Admin User Management Screen
/// Allows Admin to view and manage users in their territory
class UserManagementScreen extends StatefulWidget {
  final bool isEmbedded; // true เมื่อใช้เป็น tab ใน AdminDashboard
  final String? initialStatus;
  final Function(UserModel)? onUserSelected;

  const UserManagementScreen({
    super.key,
    this.isEmbedded = false,
    this.onUserSelected,
    this.initialStatus,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false; // Rate limiting guard
  String _searchQuery = '';
  Timer? _debounceTimer;

  bool get _isSuperAdmin {
    final user = context.read<AuthProvider>().user;
    return user?.role == UserRole.superAdmin;
  }

  @override
  void initState() {
    super.initState();
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminStateProvider>();
      await provider.loadUsers();
      final isSuperAdmin = context.read<AuthProvider>().user?.role == UserRole.superAdmin;
      if (isSuperAdmin) {
        await provider.loadDeletedUsers();
        // Auto-approve pending users
        if (provider.pendingUsers.isNotEmpty && mounted) {
           for (final user in provider.pendingUsers) {
             try {
                // Auto-Approve without showing dialogs for Super Admins
                await provider.approveUser(user.id);
             } catch (e) {
                // Silently handle or log errors during auto-approve
             }
           }
           // Refresh list after auto-approvals
           await provider.loadUsers();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value);
    });
  }

  Future<void> _approveUser(UserModel user) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Show confirmation dialog first
    bool? confirmed;
    
    // Check if Super Admin to use Luxury Dialog
    final isSuperAdmin = context.read<AuthProvider>().user?.role == UserRole.superAdmin;
    
    if (isSuperAdmin) {
       confirmed = await LuxuryDialog.show(
        context,
        title: 'ยืนยันการอนุมัติ',
        content: 'คุณต้องการอนุมัติ ${user.fullName} หรือไม่?\nสมาชิกจะสามารถเข้าใช้งานระบบได้ทันที',
        icon: PhosphorIconsRegular.sealCheck,
        accentColor: LuxuryTheme.emeraldNeon,
        confirmText: 'อนุมัติสมาชิก',
      );
    } else {
      confirmed = await AdminConfirmationDialog.showApproval(
        context,
        user: user,
      );
    }

    if (confirmed != true) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'กำลังอนุมัติ...',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await context.read<AdminStateProvider>().approveUser(user.id);

      if (!mounted) return;
      Navigator.pop(context); // ปิด loading dialog

      AdminErrorHandler.showSuccess(
        context,
        message: 'อนุมัติ ${user.fullName} เรียบร้อย',
        detail: isSuperAdmin
            ? 'สมาชิกได้รับอนุมัติเข้าใช้ระบบแล้ว'
            : 'สมาชิกถูก assign ให้คุณแล้ว และสามารถเข้าใช้งานระบบได้',
      );

      // Refresh list
      await context.read<AdminStateProvider>().loadUsers();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // ปิด loading dialog

      AdminErrorHandler.handle(
        context,
        e,
        operation: 'อนุมัติสมาชิก',
        onRetry: () => _approveUser(user),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    // Show rejection dialog with reason input
    final reason = await AdminConfirmationDialog.showRejection(
      context,
      user: user,
    );

    if (reason == null || reason.isEmpty) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      await context.read<AdminStateProvider>().rejectUser(user.id, reason);

      if (!mounted) return;
      AdminErrorHandler.showWarning(
        context,
        message: 'ปฏิเสธ ${user.fullName} เรียบร้อย',
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
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((u) {
      return u.fullName.toLowerCase().contains(query) ||
          u.phone.contains(query) ||
          (u.province?.toLowerCase().contains(query) ?? false);
    }).toList();
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
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                PhosphorIconsRegular.xCircle,
                color: AppColors.error,
                size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'ปฏิเสธคำขอ',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'เช่น ข้อมูลไม่ครบถ้วน, เอกสารไม่ถูกต้อง...',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 4,
                style: const TextStyle(),
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      PhosphorIconsRegular.info,
                      color: AppColors.warning,
                      size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เหตุผลนี้จะถูกส่งเป็นการแจ้งเตือนไปยังผู้สมัคร',
                        style: TextStyle(
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            icon: const Icon(
              PhosphorIconsRegular.x,
              size: 18,
              color: AppColors.textLight),
            label: Text(
              'ปฏิเสธ',
              style: TextStyle(
                color: AppColors.textLight,
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

  Future<void> _showDebugInfo(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Admin Debug Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugRow('ID', user.id),
              _buildDebugRow('Name', user.fullName),
              _buildDebugRow('Role', user.role.name),

              const Divider(),
              Text(
                'Territory (พื้นที่ที่ดูแล):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              _buildDebugRow('Region', user.region ?? 'null'),
              _buildDebugRow('Province', user.province ?? 'null'),
              _buildDebugRow('District', user.district ?? 'null'),
              _buildDebugRow('Subdistrict', user.subdistrict ?? 'null'),

              const SizedBox(height: 8),
              // ✅ NEW: Territory Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTerritoryDescription(user),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Divider(),
              Text(
                'คำอธิบาย:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• คุณสามารถอนุมัติได้เฉพาะสมาชิกในพื้นที่ที่คุณดูแล\n'
                '• หลังอนุมัติ สมาชิกจะถูก assign ให้คุณอัตโนมัติ\n'
                '• Super Admin สามารถจัดการได้ทุกพื้นที่',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontFamily: 'IBMPlexMono', 
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: เพิ่ม helper method นี้ต่อท้าย class
  String _getTerritoryDescription(UserModel user) {
    if (user.role == UserRole.superAdmin) {
      return '🌟 Super Admin: ดูแลทุกพื้นที่ในประเทศ';
    }

    if (user.subdistrict != null) {
      return '📍 ดูแลระดับตำบล: ${user.subdistrict}, ${user.district}, ${user.province}';
    } else if (user.district != null) {
      return '📍 ดูแลระดับอำเภอ: ${user.district}, ${user.province}';
    } else if (user.province != null) {
      return '📍 ดูแลระดับจังหวัด: ${user.province}';
    } else if (user.region != null) {
      return '📍 ดูแลระดับภูมิภาค: ${user.region}';
    }

    return '⚠️ ไม่ได้กำหนดพื้นที่ (ดูได้เฉพาะที่ assigned)';
  }

  /// Show dialog to reassign user to another admin (SUPER_ADMIN only)
  Future<void> _showReassignDialog(UserModel user) async {
    // First, fetch list of admins
    List<dynamic> admins = [];
    try {
      final adminService = context.read<AdminService>();
      admins = await adminService.getAdminList();
    } catch (e) {
      if (mounted) {
        AdminErrorHandler.handle(context, e, operation: 'โหลดรายชื่อ Admin');
      }
      return;
    }

    if (admins.isEmpty) {
      if (mounted) {
        AdminErrorHandler.showWarning(
          context,
          message: 'ไม่พบ Admin อื่นในระบบ',
        );
      }
      return;
    }

    String? selectedAdminId;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ย้าย User ไปยัง Admin อื่น',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ย้าย ${user.fullName} ไปให้ Admin:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'เลือก Admin',
                  labelStyle: const TextStyle(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: selectedAdminId,
                items: admins.map((admin) {
                  final name =
                      '${admin['firstName'] ?? ''} ${admin['lastName'] ?? ''}'
                          .trim();
                  final phone = admin['phone'] ?? '';
                  return DropdownMenuItem<String>(
                    value: admin['id'] as String?,
                    child: Text('$name ($phone)', style: const TextStyle()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAdminId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('ยกเลิก', style: const TextStyle()),
            ),
            ElevatedButton(
              onPressed: selectedAdminId != null
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminPrimary,
              ),
              child: Text(
                'ย้าย',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedAdminId != null) {
      await _reassignUser(user, selectedAdminId!);
    }
  }

  Future<void> _reassignUser(UserModel user, String newAdminId) async {
    try {
      final adminService = context.read<AdminService>();
      await adminService.reassignUser(userId: user.id, newAdminId: newAdminId);
      if (!mounted) return;

      AdminErrorHandler.showSuccess(
        context,
        message: 'ย้าย ${user.fullName} สำเร็จ',
      );
      context.read<AdminStateProvider>().loadUsers();
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(context, e, operation: 'ย้าย User');
    }
  }

  Future<void> _updateUserRole(UserModel user, UserRole newRole) async {
    try {
      final superAdminService = context.read<SuperAdminService>();
      
      String roleString;
      switch (newRole) {
        case UserRole.superAdmin:
          roleString = 'SUPER_ADMIN'; // Fixed: Match backend expectation
          break;
        case UserRole.admin:
          roleString = 'ADMIN';
          break;
        case UserRole.farmer:
          roleString = 'USER'; // Or 'FARMER' based on backend, 'USER' is common default
          break;
      }

      await superAdminService.updateUserRole(user.id, roleString);
      
      if (!mounted) return;
      AdminErrorHandler.showSuccess(
        context,
        message: 'เปลี่ยนสิทธิ์ ${user.fullName} เป็น ${_getRoleName(newRole)} สำเร็จ',
      );
      context.read<AdminStateProvider>().loadUsers();
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(context, e, operation: 'เปลี่ยนสิทธิ์ User');
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return 'เกษตรกร';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmbedded = widget.isEmbedded;
    final provider = context.watch<AdminStateProvider>();
    final authProvider = context.watch<AuthProvider>();
    final allUsers = provider.users;
    final pendingUsers = provider.pendingUsers;
    final approvedUsers = provider.approvedUsers;
    final isLoading = provider.isLoading;
    final error = provider.error;

    // Role-based gradient - Admin uses Orange, Super Admin uses Red
    final isSuperAdmin = authProvider.user?.role == UserRole.superAdmin;
    final roleGradient = isSuperAdmin
        ? AppColors.superAdminGradient
        : AppColors.adminGradient;

    int initialIndex = 0;
    if (widget.initialStatus == 'PENDING' && !isSuperAdmin) {
      initialIndex = 1;
    }

    return DefaultTabController(
      length: 3, // Super Admin: All, Approved, Deleted. Admin: All, Pending, Approved. Both have 3 tabs now.
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Stack(
          children: [
            // 1. Background Image & Overlay
            if (isSuperAdmin)
              Container(
                decoration: const BoxDecoration(
                  gradient: LuxuryTheme.backgroundGradient,
                ),
              )
            else ...[
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
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
  
            SafeArea(
              child: Column(
                children: [
                  // 2. Header Content
                  if (!isEmbedded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Row(
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                color: isSuperAdmin ? LuxuryTheme.glassSurface : Colors.white,
                                shape: BoxShape.circle,
                                border: isSuperAdmin ? Border.all(color: LuxuryTheme.glassBorder) : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isSuperAdmin ? 0.3 : 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            child: IconButton(
                              icon: const Icon(
                                PhosphorIconsRegular.arrowLeft,
                                color: Colors.black87),
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  final isSuperAdmin = context.read<AuthProvider>().user?.role == UserRole.superAdmin;
                                  context.go(isSuperAdmin ? '/super-admin/dashboard' : '/admin/dashboard');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'รายชื่อสมาชิก',
                              style: isSuperAdmin 
                                  ? TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )
                                  : TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              PhosphorIconsRegular.info,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _showDebugInfo(context),
                            tooltip: 'ตรวจสอบข้อมูล Admin',
                          ),
                        ],
                      ),
                    )
                  else
                    // Embedded header (Hero Style)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'รายชื่อสมาชิก',
                            style: isSuperAdmin
                                ? TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: LuxuryTheme.neonShadow(LuxuryTheme.cyanNeon),
                                    height: 1,
                                  )
                                : TextStyle(
                                    fontSize: 32, // Large and Bold
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1,
                                  ),
                          ),
                          // Debug Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                PhosphorIconsRegular.info,
                                color: isSuperAdmin
                                    ? AppColors.superAdminPrimary
                                    : AppColors.adminPrimary,
                              ),
                              onPressed: () => _showDebugInfo(context),
                              tooltip: 'ตรวจสอบข้อมูล Admin',
                            ),
                          ),
                        ],
                      ),
                    ),
  
                  // 3. Floating Search Bar (Glass)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSuperAdmin
                                ? Colors.black.withValues(alpha: 0.2) // Dark glass for better blending
                                : (isEmbedded
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.95)),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isSuperAdmin 
                                    ? Colors.transparent 
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: isSuperAdmin 
                                  ? Colors.white.withValues(alpha: 0.1) // Subtle border
                                  : Colors.white.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            onChanged: _onSearchChanged,
                            style: isSuperAdmin
                                ? TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  )
                                : TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent, // Override global theme
                              icon: Icon(
                                PhosphorIconsRegular.magnifyingGlass,
                                color: isSuperAdmin 
                                    ? LuxuryTheme.textSecondary 
                                    : AppColors.textSecondary),
                              hintText: 'ค้นหาชื่อ, เบอร์โทร...',
                              hintStyle: TextStyle(
                                color: isSuperAdmin 
                                    ? LuxuryTheme.textDisabled 
                                    : AppColors.textTertiary,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 20),
  
                  // 4. Modern Tabs with Role-based colors
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSuperAdmin ? LuxuryTheme.glassSurface : Colors.white,
                      borderRadius: BorderRadius.circular(23),
                      border: isSuperAdmin ? Border.all(color: LuxuryTheme.glassBorder) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: isSuperAdmin
                            ? LuxuryTheme.cyanNeon
                            : AppColors.adminPrimary,
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: [
                          BoxShadow(
                            color: (isSuperAdmin
                                    ? LuxuryTheme.cyanNeon
                                    : AppColors.adminPrimary)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: isSuperAdmin ? Colors.black : Colors.white,
                      unselectedLabelColor: isSuperAdmin 
                          ? LuxuryTheme.textSecondary 
                          : Colors.grey[600],
                      labelStyle: isSuperAdmin
                          ? TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )
                          : TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      padding: const EdgeInsets.all(4),
                      tabs: [
                        const Tab(text: 'ทั้งหมด'),
                        if (!isSuperAdmin) const Tab(text: 'รออนุมัติ'),
                        const Tab(text: 'สมาชิก'),
                        if (isSuperAdmin) const Tab(text: 'ถูกลบ'),
                      ],
                    ),
                  ),
  
                  const SizedBox(height: 16),
  
                  // 5. List Content
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                        ? _buildErrorState(error)
                        : TabBarView(
                            children: [
                              _buildUserList(_filterUsers(allUsers)),
                              if (!isSuperAdmin)
                                _buildUserList(
                                  _filterUsers(pendingUsers),
                                  showActions: true,
                                ),
                              _buildUserList(_filterUsers(approvedUsers)),
                              if (isSuperAdmin)
                                _buildUserList(
                                  _filterUsers(provider.deletedUsers),
                                  isDeletedTab: true,
                                ),
                            ],
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            PhosphorIconsRegular.warning,
            size: 48,
            color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<AdminStateProvider>().loadUsers(),
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
            label: Text('ลองใหม่', style: const TextStyle()),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users, {bool showActions = false, bool isDeletedTab = false}) {
    final isSuperAdmin = context.watch<AuthProvider>().user?.role == UserRole.superAdmin;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDeletedTab ? PhosphorIconsRegular.trash : PhosphorIconsRegular.users,
              size: 48,
              color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              isDeletedTab ? 'ไม่มีผู้ใช้ที่ถูกลบ' : 'ไม่พบสมาชิก',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<AdminStateProvider>().loadUsers();
        if (isSuperAdmin) {
          await context.read<AdminStateProvider>().loadDeletedUsers();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserListItem(
            user: user,
            showActions: showActions || isDeletedTab,
            isDeleted: isDeletedTab,
            showRole: isSuperAdmin,
            isLuxury: isSuperAdmin,
            onApprove: isDeletedTab ? () => _restoreUser(user) : () => _approveUser(user),
            onReject: isDeletedTab ? null : () => _rejectUser(user),
            onTap: () {
              if (widget.onUserSelected != null) {
                widget.onUserSelected!(user);
              } else {
                _showUserDetail(user, isDeleted: isDeletedTab);
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _restoreUser(UserModel user) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await context.read<AdminStateProvider>().restoreUser(user.id);
      if (!mounted) return;
      AdminErrorHandler.showSuccess(
        context,
        message: 'กู้คืน ${user.fullName} สำเร็จ',
      );
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(context, e, operation: 'กู้คืนผู้ใช้');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Delete User (SUPER_ADMIN only)
  Future<void> _deleteUser(UserModel user) async {
    if (_isProcessing) return;

    // Confirmation dialog
    final confirmed = await LuxuryDialog.show(
      context,
      title: 'ลบผู้ใช้',
      content: 'คุณต้องการลบ ${user.fullName} หรือไม่?\nผู้ใช้จะถูก Soft Delete และสามารถกู้คืนได้ภายหลัง',
      icon: PhosphorIconsRegular.trash,
      accentColor: AppColors.error,
      confirmText: 'ลบผู้ใช้',
      isDestructive: true,
    );
 
    if (confirmed != true) return;
    setState(() => _isProcessing = true);

    try {
      final service = context.read<SuperAdminService>();
      await service.deleteUser(user.id);
      if (!mounted) return;
      AdminErrorHandler.showSuccess(
        context,
        message: 'ลบ ${user.fullName} สำเร็จ',
        detail: 'ผู้ใช้ถูก Soft Delete สามารถกู้คืนได้ในแท็บ "ถูกลบ"',
      );
      // Refresh lists
      await context.read<AdminStateProvider>().loadUsers();
      if (_isSuperAdmin) {
        await context.read<AdminStateProvider>().loadDeletedUsers();
      }
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(context, e, operation: 'ลบผู้ใช้');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Show dialog to change user role (SUPER_ADMIN only)
  Future<void> _showChangeRoleDialog(UserModel user) async {
    UserRole? selectedRole = user.role;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  PhosphorIconsRegular.userCircle,
                  color: AppColors.warning,
                  size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'เปลี่ยนสิทธิ์ผู้ใช้',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เปลี่ยนสิทธิ์ของ ${user.fullName}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...UserRole.values.map((role) {
                return RadioListTile<UserRole>(
                  title: Text(_getRoleName(role), style: const TextStyle()),
                  subtitle: Text(
                    _getRoleDescription(role),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: role,
                  groupValue: selectedRole,
                  activeColor: AppColors.superAdminPrimary,
                  onChanged: (value) {
                    setState(() => selectedRole = value);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('ยกเลิก', style: const TextStyle()),
            ),
            ElevatedButton(
              onPressed: selectedRole != user.role
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminPrimary,
              ),
              child: Text(
                'บันทึก',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedRole != null && selectedRole != user.role) {
      await _applyRoleChange(user, selectedRole!);
    }
  }

  Future<void> _applyRoleChange(UserModel user, UserRole newRole) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      String roleString;
      switch (newRole) {
        case UserRole.superAdmin:
          roleString = 'SUPER_ADMIN';
          break;
        case UserRole.admin:
          roleString = 'ADMIN';
          break;
        case UserRole.farmer:
          roleString = 'USER';
          break;
      }

      await context.read<AdminStateProvider>().updateUserRole(user.id, roleString);
      if (!mounted) return;
      AdminErrorHandler.showSuccess(
        context,
        message: 'เปลี่ยนสิทธิ์ ${user.fullName} เป็น ${_getRoleName(newRole)} สำเร็จ',
      );
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(context, e, operation: 'เปลี่ยนสิทธิ์');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return 'ผู้ใช้ทั่วไป - บันทึกข้อมูลแปลงและ GAP';
      case UserRole.admin:
        return 'Admin - อนุมัติแปลง ดูแลสมาชิกในพื้นที่';
      case UserRole.superAdmin:
        return 'Super Admin - สิทธิ์สูงสุด จัดการทั้งระบบ';
    }
  }

  void _showUserDetail(UserModel user, {bool isDeleted = false}) {
    final isSA = context.read<AuthProvider>().user?.role == UserRole.superAdmin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isSA ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isSA ? const Border(top: BorderSide(color: LuxuryTheme.cyanNeon, width: 1)) : null,
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isSA ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isSA
                        ? LuxuryTheme.cyanNeon.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.firstName.isNotEmpty
                          ? user.firstName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSA ? LuxuryTheme.cyanNeon : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: isSA
                              ? TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )
                              : TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                        Text(
                          user.phone,
                          style: isSA
                              ? TextStyle(color: LuxuryTheme.textSecondary)
                              : TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(user.membershipStatus),
                ],
              ),
            ),

            // ⭐ Role Change (SUPER_ADMIN — prominent, right after header)
            if (isSA && user.membershipStatus == MembershipStatus.approved)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: LuxuryTheme.goldNeon.withValues(alpha: 0.5)),
                    color: LuxuryTheme.goldNeon.withValues(alpha: 0.08),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      PhosphorIconsRegular.userCircle,
                      color: LuxuryTheme.goldNeon,
                      size: 24),
                    title: Text(
                      'เปลี่ยนสิทธิ์ (Role)',
                      style: TextStyle(
                        color: LuxuryTheme.goldNeon,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Role ปัจจุบัน: ${_getRoleName(user.role)}',
                      style: TextStyle(
                        color: LuxuryTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      PhosphorIconsRegular.caretRight,
                      color: LuxuryTheme.goldNeon,
                      size: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeRoleDialog(user);
                    },
                  ),
                ),
              ),

            // Assigned info
            if (!isSA && user.membershipStatus == MembershipStatus.approved)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.userPlus,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '✅ สมาชิกของคุณ (Assigned to you)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


            // Menu: View Plots (For Approved Users)
            if (user.membershipStatus == MembershipStatus.approved)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
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
                  icon: Icon(PhosphorIconsRegular.mapTrifold,
                    color: isSA ? LuxuryTheme.emeraldNeon : AppColors.primary),
                  label: Text(
                    'ดูแปลงเกษตร',
                    style: TextStyle(
                      color: isSA ? LuxuryTheme.emeraldNeon : AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isSA ? LuxuryTheme.emeraldNeon.withValues(alpha: 0.5) : AppColors.primary,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

            Divider(color: isSA ? Colors.white12 : null),
            // Details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailRowStyled('อาชีพ', user.job ?? 'ไม่ระบุ', isSA),
                  _buildDetailRowStyled('ภูมิภาค', user.region ?? 'ไม่ระบุ', isSA),
                  _buildDetailRowStyled('จังหวัด', user.province ?? 'ไม่ระบุ', isSA),
                  _buildDetailRowStyled('อำเภอ', user.district ?? 'ไม่ระบุ', isSA),
                  _buildDetailRowStyled('ตำบล', user.subdistrict ?? 'ไม่ระบุ', isSA),
                  _buildDetailRowStyled(
                    'วันเกิด',
                    user.birthDate != null
                        ? '${user.birthDate!.day}/${user.birthDate!.month}/${user.birthDate!.year}'
                        : 'ไม่ระบุ',
                    isSA,
                  ),
                ],
              ),
            ),
            // Actions for pending users
            if (!isSA && user.membershipStatus == MembershipStatus.pending)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectUser(user);
                        },
                        icon: const Icon(PhosphorIconsRegular.x, color: AppColors.error),
                        label: Text(
                          'ปฏิเสธ',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveUser(user);
                        },
                        icon: const Icon(PhosphorIconsRegular.check),
                        label: Text('อนุมัติ', style: const TextStyle()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Super Admin action buttons
            Builder(
              builder: (context) {
                final authProvider = context.watch<AuthProvider>();
                final isSuperAdmin =
                    authProvider.user?.role == UserRole.superAdmin;

                if (isSuperAdmin &&
                    user.membershipStatus == MembershipStatus.approved) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        // Reassign Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showReassignDialog(user);
                            },
                            icon: const Icon(
                              PhosphorIconsRegular.arrowsLeftRight,
                              size: 18,
                              color: LuxuryTheme.cyanNeon),
                            label: Text(
                              'ย้าย Admin',
                              style: TextStyle(
                                color: LuxuryTheme.cyanNeon,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: LuxuryTheme.cyanNeon.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Delete User Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteUser(user);
                            },
                            icon: const Icon(
                              PhosphorIconsRegular.trash,
                              size: 18,
                              color: AppColors.error),
                            label: Text(
                              'ลบผู้ใช้',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.error,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDetailRowStyled(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? LuxuryTheme.textSecondary : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MembershipStatus status) {
    Color color;
    String text;
    switch (status) {
      case MembershipStatus.pending:
        color = AppColors.warning;
        text = 'รออนุมัติ';
        break;
      case MembershipStatus.approved:
        color = AppColors.success;
        text = 'สถานะปกติ';
        break;
      case MembershipStatus.rejected:
        color = AppColors.error;
        text = 'ถูกปฏิเสธ';
        break;
      case MembershipStatus.none:
        color = AppColors.textSecondary;
        text = 'ไม่ระบุ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
