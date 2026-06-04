import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Utility class for handling admin errors with consistent UI
class AdminErrorHandler {
  /// Handle and display an error with optional retry functionality
  static void handle(
    BuildContext context,
    Object error, {
    String operation = 'ดำเนินการ',
    VoidCallback? onRetry,
  }) {
    String message = 'เกิดข้อผิดพลาดในการ $operation';
    String detail = error.toString();

    // Parse specific error types
    if (error is Exception) {
      if (error.toString().contains('timeout')) {
        message = 'หมดเวลาการเชื่อมต่อ';
        detail = 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      } else if (error.toString().contains('unauthorized')) {
        message = 'ไม่มีสิทธิ์ในการ $operation';
        detail = 'คุณไม่มีสิทธิ์เพียงพอ';
      } else if (error.toString().contains('not found')) {
        message = 'ไม่พบข้อมูล';
        detail = 'ข้อมูลที่ขอไม่พบในระบบ';
      }
    }

    _showErrorDialog(
      context,
      title: message,
      message: detail,
      onRetry: onRetry,
    );
  }

  /// Show a success message
  static void showSuccess(
    BuildContext context, {
    String message = 'สำเร็จ',
    String? detail,
  }) {
    _showSnackBar(
      context,
      message: message,
      detail: detail,
      backgroundColor: AppColors.success,
    );
  }

  /// Show a warning message
  static void showWarning(
    BuildContext context, {
    String message = 'คำเตือน',
    String? detail,
  }) {
    _showSnackBar(
      context,
      message: message,
      detail: detail,
      backgroundColor: AppColors.warning,
    );
  }

  /// Show an error message
  static void showError(
    BuildContext context, {
    String message = 'ข้อผิดพลาด',
    String? detail,
  }) {
    _showSnackBar(
      context,
      message: message,
      detail: detail,
      backgroundColor: AppColors.error,
    );
  }

  /// Display a snack bar with message and optional detail
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    String? detail,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: detail != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              )
            : Text(message, style: GoogleFonts.prompt(color: Colors.white)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a detailed error dialog with retry option
  static void _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(message, style: GoogleFonts.prompt()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด', style: GoogleFonts.prompt()),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'ลองใหม่',
                style: GoogleFonts.prompt(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  /// Validate form field and show error
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอก$fieldName';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกเบอร์โทรศัพท์';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'เบอร์โทรศัพท์ต้องเป็น 10 หลัก';
    }
    return null;
  }
}
