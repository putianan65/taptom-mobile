import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

/// Centralized permission handling utilities
class PermissionUtils {
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
  static void _showPermissionDeniedSnackbar(
    BuildContext context,
    String permissionName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'จำเป็นต้องอนุญาตการเข้าถึง$permissionName เพื่อใช้งานฟีเจอร์นี้',
          style: GoogleFonts.prompt(),
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'ลองใหม่',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Show dialog for permanently denied permission
  static void _showPermissionPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ต้องอนุญาตการเข้าถึง$permissionName',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'คุณได้ปฏิเสธการอนุญาตถาวร กรุณาไปที่ตั้งค่าแอปเพื่อเปิดใช้งาน',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              foregroundColor: Colors.white,
            ),
            child: Text('ไปตั้งค่า', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );
  }

  /// Show dialog when service (GPS) is disabled
  static void _showServiceDisabledDialog(
    BuildContext context,
    String serviceName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$serviceName ถูกปิดอยู่',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'กรุณาเปิด $serviceName ในการตั้งค่าอุปกรณ์เพื่อใช้งานแผนที่',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              foregroundColor: Colors.white,
            ),
            child: Text('เปิดตั้งค่า', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );
  }
}
