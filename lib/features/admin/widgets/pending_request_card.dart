import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

/// Pending Request Card - แสดงข้อมูล User ที่รอการอนุมัติแบบ Premium
class PendingRequestCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const PendingRequestCard({
    super.key,
    required this.user,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withOpacity(0.1),
                    AppColors.surface,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.warning.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'รออนุมัติ',
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDate(
                        user.birthDate,
                      ), // Note: using birthDate as placeholder, likely createdDate in real app
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // User info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getAvatarColor(),
                              _getAvatarColor().withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _getAvatarColor().withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.prompt(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name and phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: GoogleFonts.prompt(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                HeroIcon(
                                  HeroIcons.phone,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user.phone,
                                  style: GoogleFonts.prompt(
                                    fontSize: 13,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      HeroIcon(
                        HeroIcons.chevronRight,
                        size: 20,
                        color: AppColors.border,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (user.province != null)
                        _buildInfoChip(
                          icon: HeroIcons.mapPin,
                          text: _buildLocationText(),
                          color: const Color(0xFF2E7D32), // Dark Green
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                      if (user.job != null && user.job!.isNotEmpty)
                        _buildInfoChip(
                          icon: HeroIcons.briefcase,
                          text: user.job!,
                          color: const Color(0xFF6A1B9A), // Dark Purple
                          bgColor: const Color(0xFFF3E5F5),
                        ),
                      if (user.region != null)
                        _buildInfoChip(
                          icon: HeroIcons.globeAlt,
                          text: user.region!,
                          color: const Color(0xFF00695C), // Dark Teal
                          bgColor: const Color(0xFFE0F2F1),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const HeroIcon(
                        HeroIcons.xMark,
                        size: 18,
                        color: Color(0xFFCF6679),
                      ),
                      label: Text(
                        'ปฏิเสธ',
                        style: GoogleFonts.prompt(
                          color: const Color(0xFFCF6679),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFFCF6679).withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const HeroIcon(
                        HeroIcons.check,
                        size: 18,
                        color: Colors.black,
                      ),
                      label: Text(
                        'อนุมัติ',
                        style: GoogleFonts.prompt(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 5,
                        shadowColor: const Color(0xFF00E676).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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

  Widget _buildInfoChip({
    required HeroIcons icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.prompt(
                fontSize: 13,
                color: color, // Dark Text
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _buildLocationText() {
    List<String> parts = [];
    if (user.district != null) parts.add('อ.${user.district}');
    if (user.province != null) parts.add('จ.${user.province}');
    return parts.join(' ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'วันนี้';
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'วันนี้';
    if (diff == 1) return 'เมื่อวาน';
    if (diff < 7) return '$diff วันที่แล้ว';

    return DateFormat('d MMM', 'th').format(date);
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
      Colors.cyan,
      Colors.amber,
    ];
    return colors[hash.abs() % colors.length];
  }
}
