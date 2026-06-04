import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Centralized error handling utilities
class ErrorUtils {
  /// Convert any error to a user-friendly Thai message
  static String getReadableError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FormatException) {
      return 'ข้อมูลไม่ถูกต้อง';
    }

    if (error is TypeError) {
      return 'เกิดข้อผิดพลาดในระบบ';
    }

    // Generic fallback
    final errorString = error.toString();

    // Check for common patterns
    if (errorString.contains('SocketException') ||
        errorString.contains('Connection refused')) {
      return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
    }

    if (errorString.contains('timeout')) {
      return 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่';
    }

    // Remove "Exception:" prefix if present
    return errorString.replaceFirst('Exception: ', '');
  }

  /// Show error snackbar with consistent styling
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final message = getReadableError(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'ลองใหม่',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show success snackbar with consistent styling
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Show warning snackbar with consistent styling
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Handle Dio-specific errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่';

      case DioExceptionType.connectionError:
        return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ต';

      case DioExceptionType.badResponse:
        return _handleStatusCode(
          error.response?.statusCode,
          error.response?.data,
        );

      case DioExceptionType.cancel:
        return 'การดำเนินการถูกยกเลิก';

      case DioExceptionType.badCertificate:
        return 'ใบรับรองความปลอดภัยไม่ถูกต้อง';

      case DioExceptionType.unknown:
      default:
        return 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
    }
  }

  /// Handle HTTP status codes
  static String _handleStatusCode(int? statusCode, dynamic responseData) {
    // Try to extract server message
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message']?.toString();
      // Handle array of messages
      if (serverMessage == null && responseData['message'] is List) {
        serverMessage = (responseData['message'] as List).join(', ');
      }
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'ข้อมูลที่ส่งไม่ถูกต้อง กรุณาตรวจสอบ';
      case 401:
        return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
      case 403:
        return 'คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้';
      case 404:
        return 'ไม่พบข้อมูลที่ต้องการ';
      case 409:
        return serverMessage ?? 'ข้อมูลซ้ำกับที่มีอยู่แล้ว';
      case 422:
        return serverMessage ?? 'ข้อมูลไม่ผ่านการตรวจสอบ';
      case 429:
        return 'คำขอมากเกินไป กรุณารอสักครู่';
      case 500:
        return 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง';
      case 502:
      case 503:
        return 'เซิร์ฟเวอร์ไม่พร้อมให้บริการชั่วคราว';
      default:
        return serverMessage ?? 'เกิดข้อผิดพลาด (รหัส: $statusCode)';
    }
  }

  /// Log error for debugging (in production, send to error tracking service)
  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    // In production, this should send to Firebase Crashlytics or similar
    // For now, just print to console in debug mode
    if (context != null) {
      debugPrint('Error in $context: $error');
    } else {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Wrap async function with error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    BuildContext? context,
    String? errorMessage,
    VoidCallback? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      logError(e, stackTrace);
      if (context != null) {
        showErrorSnackBar(
          context,
          errorMessage ?? e,
        );
      }
      onError?.call();
      return null;
    }
  }
}
