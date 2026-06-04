import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';

/// PlotCard - Display plot/field information in a scannable card format
///
/// Inspired by "Smart Farming Mobile App" and "Farming Mobile App" designs
/// from Dribbble agriculture app research.
///
/// Usage:
/// ```dart
/// PlotCard(
///   plotId: '123',
///   plotName: 'แปลงกัญชา 01',
///   area: 4.66,
///   status: 'PENDING',
///   lastUpdated: DateTime.now(),
///   onTap: () => navigateToDetails(),
/// )
/// ```
class PlotCard extends StatelessWidget {
  const PlotCard({
    super.key,
    required this.plotId,
    required this.plotName,
    required this.area,
    required this.status,
    required this.onTap,
    this.thumbnailUrl,
    this.lastUpdated,
    this.onEdit,
    this.onDelete,
  });

  final String plotId;
  final String plotName;
  final double area; // in rai
  final String status; // PENDING, APPROVED, REJECTED
  final String? thumbnailUrl;
  final DateTime? lastUpdated;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail (if exists)
            if (thumbnailUrl != null) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary.withOpacity(0.05),
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],

            // Plot Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plot name
                  Text(
                    plotName,
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.6, // Thai-friendly line height
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Area + Status
                  Row(
                    children: [
                      Text(
                        '${area.toStringAsFixed(2)} ไร่',
                        style: GoogleFonts.prompt(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(status),
                    ],
                  ),

                  // Last updated
                  if (lastUpdated != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatLastUpdated(lastUpdated!),
                      style: GoogleFonts.prompt(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'APPROVED':
        color = AppColors.success;
        label = 'ผ่านรับรอง';
        break;
      case 'REJECTED':
        color = AppColors.error;
        label = 'ไม่ผ่าน';
        break;
      case 'PENDING':
      default:
        color = AppColors.warning;
        label = 'รอตรวจสอบ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: GoogleFonts.prompt(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return 'อัปเดต ${difference.inDays ~/ 30} เดือนที่แล้ว';
    } else if (difference.inDays > 0) {
      return 'อัปเดต ${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return 'อัปเดต ${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return 'เพิ่งอัปเดต';
    }
  }
}
