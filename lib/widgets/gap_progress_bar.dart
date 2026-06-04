import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// GAPProgressBar - Visual progress indicator for GAP form completion
///
/// Inspired by "Flora Task Tracker" design showing progress tracking
/// with color-coded status indicators.
///
/// Usage:
/// ```dart
/// GAPProgressBar(
///   completed: 3,
///   total: 5,
///   label: 'ฟอร์มเสร็จสมบูรณ์',
/// )
/// ```
class GAPProgressBar extends StatelessWidget {
  const GAPProgressBar({
    super.key,
    required this.completed,
    required this.total,
    this.progressColor,
    this.label,
  });

  final int completed;
  final int total;
  final Color? progressColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Validation
    assert(completed >= 0, 'completed must be >= 0');
    assert(total > 0, 'total must be > 0');
    assert(completed <= total, 'completed must be <= total');

    final percentage = (completed / total * 100).round();
    final color = _getProgressColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Percentage and label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label ?? 'ความคืบหน้า',
              style: GoogleFonts.prompt(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: completed / total,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor ?? color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Status text
        Text(
          '$completed/$total ฟอร์มเสร็จสมบูรณ์',
          style: GoogleFonts.prompt(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(int percentage) {
    if (percentage >= 67) {
      return AppColors.success;
    } else if (percentage >= 34) {
      return AppColors.info;
    } else {
      return AppColors.warning;
    }
  }
}
