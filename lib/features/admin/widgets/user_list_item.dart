import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

/// User list item widget for Admin User Management
class UserListItem extends StatelessWidget {
  final UserModel user;
  final bool showActions;
  final bool showRole; // New property
  final bool isDeleted;
  final bool isLuxury; // New property for Super Admin theme
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const UserListItem({
    super.key,
    required this.user,
    this.showActions = false,
    this.isDeleted = false,
    this.showRole = false, // Default false
    this.isLuxury = false, // Default false
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: isLuxury
          ? BoxDecoration(
              color: LuxuryTheme.glassSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: LuxuryTheme.glassBorder),
            )
          : BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                      decoration: BoxDecoration(
                        color: isLuxury 
                            ? _getAvatarColor().withValues(alpha: 0.1) 
                            : _getAvatarColor(),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isLuxury
                            ? [
                                BoxShadow(
                                  color: _getAvatarColor().withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: _getAvatarColor().withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        border: isLuxury 
                            ? Border.all(color: _getAvatarColor().withValues(alpha: 0.3)) 
                            : null,
                      ),
                    alignment: Alignment.center,
                      child: Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '?',
                        style: isLuxury 
                            ? TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getAvatarColor(),
                              )
                            : TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                      ),
                  ),
                  const SizedBox(width: 16),

                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                  user.fullName,
                                  style: isLuxury
                                      ? TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                          height: 1.2,
                                        )
                                      : TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                          height: 1.2,
                                        ),
                                ),
                            ),
                            if (showRole) ...[
                              const SizedBox(width: 8),
                              _buildRoleBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                PhosphorIconsRegular.phone,
                                size: 12,
                                color: AppColors.success),
                            ),
                            const SizedBox(width: 8),
                              Text(
                                user.phone,
                                style: isLuxury
                                    ? TextStyle(
                                        fontSize: 13,
                                        color: LuxuryTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      )
                                    : TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge (Top right)
                  // _buildStatusBadge(), // Moving status badge to specific place or keep it here?
                  // Keeping it simple for now, sticking to row
                ],
              ),

              const SizedBox(height: 16),

              // Location info & Status in a Row
              Row(
                children: [
                  if (user.province != null || user.district != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isLuxury 
                              ? LuxuryTheme.glassSurface 
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isLuxury 
                                  ? LuxuryTheme.glassBorder 
                                  : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.mapPin,
                              size: 14,
                              color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                  user.locationDisplay,
                                  style: isLuxury
                                      ? TextStyle(
                                          fontSize: 12,
                                          color: LuxuryTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        )
                                      : TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (user.province != null || user.district != null)
                    const SizedBox(width: 8),

                  _buildStatusBadge(),
                ],
              ),

              // Action buttons for pending users or deleted users
              if (showActions &&
                  (user.membershipStatus == MembershipStatus.pending || isDeleted))
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      // Only show reject for non-deleted users
                      if (!isDeleted && onReject != null)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: onReject,
                            icon: Icon(
                              PhosphorIconsRegular.x,
                              size: 18,
                              color: AppColors.error),
                            label: Text(
                              'ปฏิเสธ',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.error.withValues(alpha: 0.1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      if (!isDeleted && onReject != null)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: isDeleted ? 1 : 2,
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: Icon(
                            isDeleted ? PhosphorIconsRegular.arrowsClockwise : PhosphorIconsRegular.check,
                            size: 18,
                            color: AppColors.textLight),
                          label: Text(
                            isDeleted ? 'กู้คืน' : 'อนุมัติสมาชิก',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDeleted ? AppColors.superAdminPrimary : AppColors.success,
                            elevation: 4,
                            shadowColor: (isDeleted ? AppColors.superAdminPrimary : AppColors.success).withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }

  Color _getAvatarColor() {
    // Generate consistent color based on user name
    final hash = user.fullName.hashCode;
    final colors = isLuxury 
        ? [
            LuxuryTheme.cyanNeon,
            LuxuryTheme.goldNeon,
            LuxuryTheme.purpleNeon,
            LuxuryTheme.emeraldNeon,
          ]
        : [
            AppColors.primary,
            Colors.teal,
            Colors.orange,
            Colors.purple,
            Colors.indigo,
            Colors.pink,
          ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (user.membershipStatus) {
      case MembershipStatus.pending:
        bgColor = const Color(0xFFFFF3E0); // Orange 50
        textColor = const Color(0xFFEF6C00); // Orange 800
        text = 'รออนุมัติ';
        icon = PhosphorIconsRegular.clock;
        break;
      case MembershipStatus.approved:
        bgColor = const Color(0xFFE8F5E9); // Green 50
        textColor = const Color(0xFF2E7D32); // Green 800
        text = 'สถานะปกติ';
        icon = PhosphorIconsFill.checkCircle;
        break;
      case MembershipStatus.rejected:
        bgColor = isLuxury ? const Color(0xFFFFEBEE).withValues(alpha: 0.1) : const Color(0xFFFFEBEE); // Red 50
        textColor = isLuxury ? const Color(0xFFFF5252) : const Color(0xFFC62828); // Red 800
        text = 'ถูกปฏิเสธ';
        icon = PhosphorIconsRegular.xCircle;
        break;
      case MembershipStatus.none:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        text = 'ไม่ระบุ';
        icon = PhosphorIconsRegular.question;
        break;
        break;
    }

    if (isLuxury) {
      // Adjust standard colors for dark theme if not explicitly overridden
      if (textColor == const Color(0xFF2E7D32)) textColor = LuxuryTheme.emeraldNeon; // Green 800 -> Neon Green
      if (bgColor == const Color(0xFFE8F5E9)) bgColor = LuxuryTheme.emeraldNeon.withValues(alpha: 0.1);
      
      if (textColor == const Color(0xFFEF6C00)) textColor = LuxuryTheme.goldNeon; // Orange 800 -> Neon Gold
      if (bgColor == const Color(0xFFFFF3E0)) bgColor = LuxuryTheme.goldNeon.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: isLuxury
                ? TextStyle(
                    fontSize: 12, // Increased size
                    color: textColor,
                    fontWeight: FontWeight.normal,
                  )
                : TextStyle(
                    fontSize: 12, // Increased size
                    color: textColor,
                    fontWeight: FontWeight.bold, // Bold
                  ),
          ),
        ],
      ),
    );
  }
  Widget _buildRoleBadge() {
    String text;
    Color color;
    Color bgColor;

    switch (user.role) {
      case UserRole.superAdmin:
        text = 'Super Admin';
        color = isLuxury ? LuxuryTheme.purpleNeon : AppColors.superAdminPrimary;
        bgColor = isLuxury ? LuxuryTheme.purpleNeon.withValues(alpha: 0.1) : AppColors.superAdminPrimary.withValues(alpha: 0.1);
        break;
      case UserRole.admin:
        text = 'Admin';
        color = isLuxury ? LuxuryTheme.cyanNeon : AppColors.adminPrimary;
        bgColor = isLuxury ? LuxuryTheme.cyanNeon.withValues(alpha: 0.1) : AppColors.adminPrimary.withValues(alpha: 0.1);
        break;
      case UserRole.farmer:
      default:
        // Don't show badge for Farmer to reduce clutter, or show minimal?
        // Let's not show anything if it's default/farmer, 
        // OR show it if explicitly requested?
        // The calling code checks `showRole`. If showRole is true, we want to distinguish.
        // So let's show 'Farmer' too.
        text = 'Farmer';
        color = isLuxury ? LuxuryTheme.emeraldNeon : AppColors.primary;
        bgColor = isLuxury ? LuxuryTheme.emeraldNeon.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: isLuxury
            ? TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              )
            : TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
      ),
    );
  }
}
