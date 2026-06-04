import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_provider.dart';
import '../widgets/custom_popup.dart';
import '../network/api_exception.dart';

class ErrorHandler {
  static Future<void> handleError(BuildContext context, dynamic error) async {
    if (!context.mounted) return;

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          // Unauthorized: Auto logout
          await context.read<AuthProvider>().signOut();
          if (context.mounted) {
             context.go('/login');
             CustomPopup.showError(
               context,
               title: 'เซสชั่นหมดอายุ',
               message: 'กรุณาเข้าสู่ระบบใหม่',
             );
          }
          break;
        case 403:
          await CustomPopup.showError(
            context,
            title: 'ไม่มีสิทธิ์เข้าถึง',
            message: error.message,
          );
          break;
        case 404:
          await CustomPopup.showError(
            context,
            title: 'ไม่พบข้อมูล',
            message: error.message,
          );
          break;
        case 500:
          await CustomPopup.showError(
            context,
            title: 'ข้อผิดพลาดเซิร์ฟเวอร์',
            message: 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ กรุณาลองใหม่อีกครั้ง',
          );
          break;
        default:
          await CustomPopup.showError(
            context,
            message: error.message,
          );
      }
    } else {
      await CustomPopup.showError(
        context,
        message: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
