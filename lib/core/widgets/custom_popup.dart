import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Custom popup utility widget for showing info, error, and success messages
class CustomPopup {
  /// Show success message popup
  static Future<void> showSuccess(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    String? buttonText,
    VoidCallback? onDismiss,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 48,
        ),
        title: Text(
          title ?? 'สำเร็จ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.prompt(fontSize: 14)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (onConfirm != null) {
                onConfirm();
              } else {
                onDismiss?.call();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(
              buttonText ?? 'ตกลง',
              style: GoogleFonts.prompt(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Show API error message popup
  static Future<void> showApiError(
    BuildContext context, {
    String? title,
    required String message,
    String? code,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: AppColors.error, size: 48),
        title: Text(
          title ?? 'ข้อผิดพลาด',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.prompt(fontSize: 14)),
            if (code != null) ...[
              const SizedBox(height: 8),
              Text(
                'Code: $code',
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('ปิด', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show error message popup
  static Future<void> showError(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: AppColors.error, size: 48),
        title: Text(
          title ?? 'ข้อผิดพลาด',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.prompt(fontSize: 14)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('ตกลง', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show info message popup
  static Future<void> showInfo(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info, color: AppColors.primary, size: 48),
        title: Text(
          title ?? 'ข้อมูล',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.prompt(fontSize: 14)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('ตกลง', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show warning message popup
  static Future<void> showWarning(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: AppColors.warning, size: 48),
        title: Text(
          title ?? 'คำเตือน',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.prompt(fontSize: 14)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text('ตกลง', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Internal method to show the popup
  static void _showPopup(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String? detail,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: iconColor, size: 48),
        title: Text(
          title,
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.prompt(fontSize: 14)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: iconColor),
            child: Text('ตกลง', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show a popup with custom buttons
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? detail,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.prompt()),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText, style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              confirmText,
              style: GoogleFonts.prompt(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
