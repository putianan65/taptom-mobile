import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/admin_error_handler.dart';
import '../../../data/models/user_model.dart';
import '../screens/admin_plot_list_screen.dart';
import '../providers/admin_state_provider.dart';
import 'edit_user_dialog.dart';

/// User Detail Bottom Sheet - แสดงข้อมูล User ครบถ้วน
class UserDetailSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReassign;
  final Function(UserRole)? onRoleChange;
  final bool showActions;
  final bool isSuperAdmin;

  const UserDetailSheet({
    super.key,
    required this.user,
    this.onApprove,
    this.onReject,
    this.onReassign,
    this.onRoleChange,
    this.showActions = true,
    this.isSuperAdmin = false,
  });

  static Future<void> show(
    BuildContext context, {
    required UserModel user,
    VoidCallback? onApprove,
    VoidCallback? onReject,
    VoidCallback? onReassign,
    Function(UserRole)? onRoleChange,
    bool showActions = true,
    bool isSuperAdmin = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailSheet(
        user: user,
        onApprove: onApprove,
        onReject: onReject,
        onReassign: onReassign,
        onRoleChange: onRoleChange,
        showActions: showActions,
        isSuperAdmin: isSuperAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar & Name
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_getAvatarColor(), _getAvatarColor().withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRoleName(user.role),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildInfoRow(PhosphorIconsRegular.phone, 'เบอร์โทร', user.phone ?? '-'),
                if (user.birthDate != null)
                  _buildInfoRow(PhosphorIconsRegular.cake, 'วันเกิด', _formatBirthdate(user.birthDate!)),
                if (user.province != null)
                  _buildInfoRow(PhosphorIconsRegular.mapPin, 'จังหวัด', user.province!),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (showActions) _buildActionButtons(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (user.membershipStatus) {
      case MembershipStatus.pending:
        return Colors.orange;
      case MembershipStatus.approved:
        return Colors.green;
      case MembershipStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (user.membershipStatus) {
      case MembershipStatus.pending:
        return 'รอการอนุมัติ';
      case MembershipStatus.approved:
        return 'อนุมัติแล้ว';
      case MembershipStatus.rejected:
        return 'ถูกปฏิเสธ';
      default:
        return 'ไม่ระบุ';
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final isPending = user.membershipStatus == MembershipStatus.pending;
    final isApproved = user.membershipStatus == MembershipStatus.approved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ... Existing Pending Actions ...
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onReject?.call();
                    },
                    icon: const Icon(
                      PhosphorIconsRegular.x,
                      size: 20,
                      color: AppColors.error),
                    label: Text(
                      'ปฏิเสธ',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onApprove?.call();
                    },
                    icon: const Icon(
                      PhosphorIconsRegular.check,
                      size: 20,
                      color: Colors.white),
                    label: Text(
                      'อนุมัติ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor: AppColors.success.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Approved Actions (Reassign & Change Role)
          if (isApproved && isSuperAdmin) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReassign != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onReassign?.call();
                      },
                      icon: const Icon(
                        PhosphorIconsRegular.arrowsLeftRight,
                        size: 20,
                        color: Colors.purple),
                      label: Text(
                        'ย้าย Admin',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.purple),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                if (onReassign != null && onRoleChange != null)
                  const SizedBox(width: 8),
                if (onRoleChange != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRoleDialog(context),
                      icon: const Icon(
                        PhosphorIconsRegular.shieldCheck,
                        size: 20,
                        color: Colors.orange),
                      label: Text(
                        'เปลี่ยน Role',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เปลี่ยนสิทธิ์ผู้ใช้', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Farmer', style: const TextStyle()),
              leading: const Icon(PhosphorIconsRegular.tractor),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close sheet
                onRoleChange?.call(UserRole.farmer);
              },
            ),
            ListTile(
              title: Text('Admin', style: const TextStyle()),
              leading: const Icon(PhosphorIconsRegular.userGear),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close sheet
                onRoleChange?.call(UserRole.admin);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatBirthdate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'th').format(date);
  }

  Color _getAvatarColor() {
    final hash = user.fullName.hashCode;
    final colors = [
      AppColors.primary,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
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
}
