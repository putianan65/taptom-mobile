import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/constants/app_colors.dart';

/// Premium Stat Card with glassmorphism and gradient effect
class PremiumStatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final HeroIcons icon;
  final VoidCallback? onTap;

  const PremiumStatCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surface, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
            BoxShadow(
              color: AppColors.surface.withOpacity(0.8),
              offset: const Offset(-4, -4),
              blurRadius: 12,
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with glow
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: HeroIcon(
                icon,
                color: color,
                size: 26,
                style: HeroIconStyle.solid,
              ),
            ),
            const SizedBox(height: 16),

            // Animated count
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: int.tryParse(count) ?? 0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // Title
            Text(
              title,
              style: GoogleFonts.prompt(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
