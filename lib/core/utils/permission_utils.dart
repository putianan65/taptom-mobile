import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/widgets.dart';

/// Centralized permission handling utilities
class PermissionUtils {
  /// Asks once for notification permission. Never jumps to system
  /// settings on its own; the settings screen explains how instead.
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request location permission (for maps)
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showServiceDisabledDialog(context, 'GPS');
      }
      return false;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          _showPermissionDeniedSnackbar(context, 'ตำแหน่ง');
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionPermanentlyDeniedDialog(context, 'ตำแหน่ง');
      }
      return false;
    }

    return true;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) return true;

      if (context.mounted) {
        _showPermissionDeniedSnackbar(context, 'กล้อง');
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionPermanentlyDeniedDialog(context, 'กล้อง');
      }
      return false;
    }

    return false;
  }

  /// Request gallery/photos permission
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    var status = await Permission.photos.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.photos.request();
      if (status.isGranted) return true;

      if (context.mounted) {
        _showPermissionDeniedSnackbar(context, 'แกลเลอรี่');
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionPermanentlyDeniedDialog(context, 'แกลเลอรี่');
      }
      return false;
    }

    return false;
  }

  /// Show snackbar for denied permission
  static void _showPermissionDeniedSnackbar(BuildContext context, String name) {
    AppToast.show(
      context,
      'ต้องอนุญาตการเข้าถึง$nameเพื่อใช้ฟังก์ชันนี้',
      tone: Tone.warning,
    );
  }

  static Future<void> _showPermissionPermanentlyDeniedDialog(
    BuildContext context,
    String name,
  ) async {
    final open = await AppDialogs.confirm(
      context,
      title: 'ต้องการสิทธิ์เข้าถึง$name',
      message: 'สิทธิ์นี้ถูกปิดไว้ เปิดได้ที่การตั้งค่าของอุปกรณ์ แล้วกลับมาใช้งานอีกครั้ง',
      confirmLabel: 'เปิดการตั้งค่า',
      icon: AppIcons.settings,
    );
    if (open) await openAppSettings();
  }

  static Future<void> _showServiceDisabledDialog(
    BuildContext context,
    String service,
  ) async {
    final open = await AppDialogs.confirm(
      context,
      title: 'กรุณาเปิด $service',
      message: 'เปิดบริการตำแหน่งของอุปกรณ์เพื่อแสดงตำแหน่งปัจจุบันบนแผนที่',
      confirmLabel: 'เปิดการตั้งค่า',
      icon: AppIcons.locate,
    );
    if (open) await Geolocator.openLocationSettings();
  }
}
