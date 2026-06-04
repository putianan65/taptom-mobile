import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// EmptyState - Friendly message when no data exists with actionable CTA
///
/// Inspired by clean empty state designs across all Dribbble agriculture apps,
/// particularly "Nogyo Farming" and "Farming Mobile App" approaches.
///
/// Usage:
/// ```dart
/// EmptyState(
///   icon: Icons.grass,
///   title: 'ยังไม่มีแปลงปลูก',
///   message: 'สร้างแปลงแรกเพื่อเริ่มบันทึกข้อมูล GAP',
///   ctaText: '+ สร้างแปลงใหม่',
///   onCtaTap: () => navigateToMapDrawing(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaText,
    this.onCtaTap,
  }) : assert(
         ctaText == null || onCtaTap != null,
         'If ctaText is provided, onCtaTap must also be provided',
       );

  final IconData icon;
  final String title; // Max 50 characters
  final String message; // Max 150 characters
  final String? ctaText;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: GoogleFonts.prompt(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // CTA button (if provided)
            if (ctaText != null && onCtaTap != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48, // Large touch target
                child: ElevatedButton(
                  onPressed: onCtaTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    ctaText!,
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
