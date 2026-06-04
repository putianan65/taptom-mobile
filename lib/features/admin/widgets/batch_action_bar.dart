import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/constants/app_colors.dart';

/// Batch action bar for multi-selection operations
class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onApproveAll;
  final VoidCallback onRejectAll;
  final VoidCallback onClearSelection;

  const BatchActionBar({
    super.key,
    required this.selectedCount,
    required this.onApproveAll,
    required this.onRejectAll,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: selectedCount > 0 ? 80 : 0,
      child: selectedCount > 0
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Selection Count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'เลือก $selectedCount รายการ',
                      style: GoogleFonts.prompt(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Clear Selection
                  IconButton(
                    onPressed: onClearSelection,
                    icon: const HeroIcon(
                      HeroIcons.xMark,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Reject All
                  ElevatedButton.icon(
                    onPressed: onRejectAll,
                    icon: const HeroIcon(
                      HeroIcons.xCircle,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'ปฏิเสธ',
                      style: GoogleFonts.prompt(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Approve All
                  ElevatedButton.icon(
                    onPressed: onApproveAll,
                    icon: const HeroIcon(
                      HeroIcons.checkCircle,
                      size: 18,
                      color: AppColors.success,
                    ),
                    label: Text(
                      'อนุมัติ',
                      style: GoogleFonts.prompt(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
