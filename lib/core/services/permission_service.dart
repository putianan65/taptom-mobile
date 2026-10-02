import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';

/// Permission Service for handling runtime permissions
class PermissionService {
  /// Request notification permission (Android 13+ / iOS)
  /// ไม่ต้องใช้ BuildContext เพราะเรียกตอน app start ได้
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    
    return false;
  }

  /// ตรวจสอบสถานะ notification permission
  static Future<bool> checkNotificationPermission() async {
    return await Permission.notification.status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context, 'กล้อง', 'ถ่ายภาพและวิเคราะห์พืช');
      return false;
    }

    return false;
  }

  /// Request photos/gallery permission
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      // For Android 13+, use photos permission; for older versions, use storage
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        status = await Permission.photos.status;
        if (status.isDenied) {
          status = await Permission.photos.request();
        }
      } else {
        status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }
    } else {
      status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context, 'รูปภาพ', 'เลือกรูปภาพเพื่อวิเคราะห์');
      return false;
    }

    return false;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context, 'ไมโครโฟน', 'พูดเพื่อพิมพ์ข้อความ');
      return false;
    }

    return false;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        'ตำแหน่งที่ตั้ง',
        'แสดงตำแหน่งแปลงของคุณ',
      );
      return false;
    }

    return false;
  }

  /// Get Android SDK version
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    // Default to assuming Android 13+ for safety
    return 33;
  }

  /// Show dialog to open app settings
  static Future<void> _showSettingsDialog(
    BuildContext context,
    String permissionName,
    String reason,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                PhosphorIconsRegular.warning,
                color: Colors.orange,
                size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ต้องการสิทธิ์การเข้าถึง',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'แอปต้องการสิทธิ์เข้าถึง$permissionNameเพื่อ$reason',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.info,
                    color: Colors.blue,
                    size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'กรุณาเปิดสิทธิ์ในการตั้งค่าเครื่อง',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            icon: const Icon(
              PhosphorIconsRegular.gear,
              size: 18,
              color: Colors.white),
            label: Text(
              'เปิดการตั้งค่า',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
