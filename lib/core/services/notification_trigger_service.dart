import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Centralized Service สำหรับ trigger notifications เมื่อเกิด events ต่างๆ
/// ใช้ POST /notifications API โดยตรงผ่าน ApiClient
class NotificationTriggerService {
  final ApiClient _apiClient = ApiClient();

  // ─── Helper: สร้าง notification ─────────────────────────────────

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? createdBy,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.notifications,
        data: {
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          if (data != null) 'data': data,
          if (actionUrl != null) 'actionUrl': actionUrl,
          if (createdBy != null) 'createdBy': createdBy,
        },
      );
    } catch (e) {
      // Notification ไม่ควร block flow หลัก → silently log
      debugPrint('⚠️ Failed to create notification ($type): $e');
    }
  }

  // ─── 1. User สร้างแปลง → แจ้ง Admin ทุกคน ───────────────────────

  Future<void> onPlotCreated({
    required String plotId,
    required String plotName,
    required String userId,
    required List<String> adminIds,
  }) async {
    for (final adminId in adminIds) {
      await _createNotification(
        userId: adminId,
        title: 'มีแปลงใหม่รอตรวจสอบ',
        message: 'เกษตรกรสร้างแปลง "$plotName" รอการตรวจสอบ',
        type: 'PLOT_CREATED',
        data: {
          'plotId': plotId,
          'plotName': plotName,
          'createdBy': userId,
        },
        actionUrl: '/admin/plots/$plotId',
        createdBy: userId,
      );
    }
  }

  // ─── 2. Admin อนุมัติแปลง → แจ้ง User ─────────────────────────

  Future<void> onPlotApproved({
    required String plotId,
    required String plotName,
    required String userId,
    required String approvedBy,
  }) async {
    await _createNotification(
      userId: userId,
      title: 'แปลงได้รับการอนุมัติ',
      message: 'แปลง "$plotName" ได้รับการอนุมัติแล้ว',
      type: 'PLOT_APPROVED',
      data: {
        'plotId': plotId,
        'plotName': plotName,
        'approvedBy': approvedBy,
      },
      actionUrl: '/plots/$plotId',
      createdBy: approvedBy,
    );
  }

  // ─── 3. Admin ปฏิเสธแปลง → แจ้ง User ─────────────────────────

  Future<void> onPlotRejected({
    required String plotId,
    required String plotName,
    required String userId,
    required String rejectedBy,
    required String reason,
  }) async {
    await _createNotification(
      userId: userId,
      title: 'แปลงถูกปฏิเสธ',
      message: 'แปลง "$plotName" ถูกปฏิเสธ กรุณาตรวจสอบเหตุผล',
      type: 'PLOT_REJECTED',
      data: {
        'plotId': plotId,
        'plotName': plotName,
        'reason': reason,
        'rejectedBy': rejectedBy,
      },
      actionUrl: '/plots/$plotId',
      createdBy: rejectedBy,
    );
  }

  // ─── 4. User ส่ง GAP → แจ้ง Admin ทุกคน ──────────────────────

  Future<void> onGapSubmitted({
    required String plotId,
    required String plotName,
    required String userId,
    required List<String> adminIds,
    String? gapRecordId,
  }) async {
    for (final adminId in adminIds) {
      await _createNotification(
        userId: adminId,
        title: 'มีการส่ง GAP ใหม่',
        message: 'เกษตรกรส่งข้อมูล GAP สำหรับแปลง "$plotName"',
        type: 'GAP_SUBMITTED',
        data: {
          'plotId': plotId,
          'plotName': plotName,
          if (gapRecordId != null) 'gapRecordId': gapRecordId,
          'submittedBy': userId,
        },
        actionUrl: '/admin/gap/$plotId',
        createdBy: userId,
      );
    }
  }

  // ─── 5. Admin อนุมัติ GAP → แจ้ง User ─────────────────────────

  Future<void> onGapApproved({
    required String plotId,
    required String plotName,
    required String userId,
    required String approvedBy,
    String? gapRecordId,
  }) async {
    await _createNotification(
      userId: userId,
      title: 'ข้อมูล GAP ได้รับการอนุมัติ',
      message: 'ข้อมูล GAP สำหรับแปลง "$plotName" ได้รับการอนุมัติแล้ว',
      type: 'GAP_APPROVED',
      data: {
        'plotId': plotId,
        'plotName': plotName,
        if (gapRecordId != null) 'gapRecordId': gapRecordId,
        'approvedBy': approvedBy,
      },
      actionUrl: '/plots/$plotId/gap',
      createdBy: approvedBy,
    );
  }

  // ─── 6. Admin ปฏิเสธ GAP → แจ้ง User ─────────────────────────

  Future<void> onGapRejected({
    required String plotId,
    required String plotName,
    required String userId,
    required String rejectedBy,
    required String reason,
    String? gapRecordId,
  }) async {
    await _createNotification(
      userId: userId,
      title: 'ข้อมูล GAP ไม่ผ่านการอนุมัติ',
      message: 'ข้อมูล GAP สำหรับแปลง "$plotName" ไม่ผ่านการตรวจสอบ',
      type: 'GAP_REJECTED',
      data: {
        'plotId': plotId,
        'plotName': plotName,
        'reason': reason,
        if (gapRecordId != null) 'gapRecordId': gapRecordId,
        'rejectedBy': rejectedBy,
      },
      actionUrl: '/plots/$plotId/gap',
      createdBy: rejectedBy,
    );
  }

  // ─── 7. Admin อนุมัติสมาชิก → แจ้ง User ───────────────────────

  Future<void> onUserApproved({
    required String userId,
    required String approvedBy,
  }) async {
    await _createNotification(
      userId: userId,
      title: 'การสมัครสมาชิกได้รับการอนุมัติ',
      message: 'ยินดีต้อนรับสู่ระบบ GAP',
      type: 'USER_APPROVED',
      data: {'approvedBy': approvedBy},
      actionUrl: '/home',
      createdBy: approvedBy,
    );
  }

  // ─── 8. Admin ปฏิเสธสมาชิก → แจ้ง User ────────────────────────

  Future<void> onUserRejected({
    required String userId,
    required String rejectedBy,
    required String reason,
  }) async {
    await _createNotification(
      userId: userId,
      title: 'การสมัครสมาชิกถูกปฏิเสธ',
      message: 'กรุณาตรวจสอบเหตุผลและสมัครใหม่อีกครั้ง',
      type: 'USER_REJECTED',
      data: {
        'reason': reason,
        'rejectedBy': rejectedBy,
      },
      actionUrl: '/profile',
      createdBy: rejectedBy,
    );
  }

  // ─── 9. User แก้ไข Record → แจ้ง Admin ────────────────────────

  Future<void> onRecordEdited({
    required String plotId,
    required String formType,
    required String recordId,
    required List<String> adminIds,
  }) async {
    for (final adminId in adminIds) {
      await _createNotification(
        userId: adminId,
        title: 'มีการแก้ไขข้อมูล',
        message: 'ผู้ใช้แก้ไขข้อมูล $formType ของแปลง',
        type: 'RECORD_EDITED',
        data: {
          'plotId': plotId,
          'recordId': recordId,
          'formType': formType,
        },
        actionUrl: '/admin/plots/$plotId',
      );
    }
  }
}
