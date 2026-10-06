import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/analytics_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/plot_model.dart'; // Fixed: Import PlotModel
import '../../data/models/pdpa_log_model.dart';
import '../../data/models/conversation_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../data/models/user_model.dart';
import 'audit_service.dart';
import 'notification_trigger_service.dart';

class AdminService {
  final ApiClient _apiClient = ApiClient();
  final AuditService _auditService = AuditService();
  final NotificationTriggerService _triggerService = NotificationTriggerService();

  // ==================== SUPER_ADMIN ONLY ====================

  /// Create a new Admin (SUPER_ADMIN only)
  Future<Map<String, dynamic>> createAdmin({
    required String phone,
    required String firstName,
    required String lastName,
    required String job,
    required String region,
    String? province, // NEW
    String? district, // NEW
    String? subDistrict, // NEW
    required String birthday,
    required String pin,
  }) async {
    try {
      final data = <String, dynamic>{
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'job': job,
        'region': region,
        'birthday': birthday,
        'pin': pin,
      };

      // Add optional location fields
      if (province != null && province.isNotEmpty) data['province'] = province;
      if (district != null && district.isNotEmpty) data['district'] = district;
      if (subDistrict != null && subDistrict.isNotEmpty) {
        data['subDistrict'] = subDistrict;
      }

      final response = await _apiClient.post(
        ApiEndpoints.adminCreate,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception(
        'สร้าง Admin ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Get list of all Admins (SUPER_ADMIN only)
  Future<List<dynamic>> getAdminList() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminList);

      // Handle both list directly or { data: [] } format
      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      return data;
    } on ApiException catch (e) {
      throw Exception(
        'ดึงข้อมูล Admin ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  Future<List<dynamic>> getSuperAdmins() async {
    try {
      // 1. Try fetching from /users with role query param
      // Note: If backend forces scope to "my farmers", this might return empty or farmers.
      // We must filter client-side to be sure we don't return farmers.
      final response = await _apiClient.get(
        ApiEndpoints.users, 
        queryParameters: {'role': 'SUPER_ADMIN', 'limit': 100},
      );

      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      final List<dynamic> users = data is List ? data : [];

      // 2. Strict Filter: Only return users who actually have SUPER_ADMIN role
      // This prevents "Farmers" from showing up if the backend ignored the ?role= param
      return users.where((u) {
        final role = u['role']?.toString().toUpperCase();
        return role == 'SUPER_ADMIN';
      }).toList();

    } catch (e) {
      debugPrint('Could not fetch Super Admins: $e');
      return [];
    }
  }

  /// Delete Admin (SUPER_ADMIN only) - Soft delete
  Future<void> deleteAdmin(String adminId) async {
    try {
      await _apiClient.delete(ApiEndpoints.adminDelete(adminId));
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        throw Exception('ไม่สามารถลบบัญชีของตัวเองได้');
      }
      throw Exception(
        'ลบ Admin ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Reassign a user to a different admin
  Future<void> reassignUser({
    required String userId,
    required String newAdminId,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.adminReassign(userId),
        data: {'newAdminId': newAdminId},
      );
    } on ApiException catch (e) {
      throw Exception(
        'ย้าย User ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  // ==================== Dashboard & Stats ====================

  /// Get admin dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminStats);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Return default/mock stats if API fails or not implemented yet
      return {'pending': 0, 'approved': 0, 'total': 0};
    }
  }

  /// Get list of plots for admin (can filter by status)
  /// If status is null, returns all plots
  Future<List<dynamic>> getAdminPlots({String? status, String? userId}) async {
    try {
      final queryParams = <String, dynamic>{'include': 'owner'};
      
      // Fix: Backend defaults to PENDING if status is missing. 
      // We send empty string to get ALL plots (PENDING + APPROVED + REJECTED)
      String statusParam = status ?? '';
      if (statusParam == 'ALL') statusParam = '';
      
      queryParams['status'] = statusParam;

      if (userId != null) queryParams['userId'] = userId;

      final response = await _apiClient.get(
        ApiEndpoints.adminPlots,
        queryParameters: queryParams,
      );

      // Handle both list directly or { data: [] } format
      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      
      return data;
    } catch (e) {
      return [];
    }
  }

  /// Create plot for a user (Admin)
  Future<void> createPlotForUser({required String userId, required PlotModel plot}) async {
    try {
      // Sending userId in body or query param depending on backend
      // Assuming generic POST /admin/plots accepts body with userId
      final data = plot.toJson();
      data['userId'] = userId; 

      await _apiClient.post(
        ApiEndpoints.plots,
        data: data,
      );
    } on ApiException catch (e) {
       // Fallback: If 404, maybe use generic plots endpoint? 
       // But generic endpoint usually ignores user ID.
       throw Exception('สร้างแปลงให้เกษตรกรไม่สำเร็จ: ${e.serverMessage ?? e.message}');
    }
  }

  /// Get plot detail for admin (includes owner info and full status)
  /// Uses generic plots endpoint since admin-specific detail endpoint may not exist
  Future<Map<String, dynamic>> getPlotDetail(String plotId) async {
    try {
      // Use generic endpoint since admin-specific detail endpoint doesn't exist
      final response = await _apiClient.get(
        ApiEndpoints.plot(plotId),
        queryParameters: {'include': 'owner'},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Return empty map to allow fallback to initial data
      debugPrint('Could not fetch plot detail: $e');
      return {};
    }
  }

  /// Update plot geometry (Edit Polygon)
  Future<void> updatePlotGeometry(String plotId, List<List<double>> coordinates) async {
    try {
      await _apiClient.patch(
        '/plots/$plotId', // Use generic endpoint as confirmed by backend team
        data: {
          'geometry': {
            'type': 'Polygon',
            'coordinates': [coordinates], // Nested array for Polygon ring
          }
        },
      );
    } on ApiException catch (e) {
       throw Exception('แก้ไขพิกัดไม่สำเร็จ: ${e.serverMessage ?? e.message}');
    }
  }

  /// Approve a plot
  /// [ownerId] & [plotName] & [adminId] ใช้สำหรับ trigger notification
  Future<void> approvePlot(
    String plotId, {
    String? ownerId,
    String? plotName,
    String? adminId,
  }) async {
    try {
      await _apiClient.post(ApiEndpoints.adminApprove(plotId));
    } on ApiException catch (e) {
      throw Exception(
        'อนุมัติไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }

    // Trigger notification → แจ้ง User เจ้าของแปลง
    if (ownerId != null) {
      await _triggerService.onPlotApproved(
        plotId: plotId,
        plotName: plotName ?? 'แปลง',
        userId: ownerId,
        approvedBy: adminId ?? 'admin',
      );
    }
  }

  /// Reject a plot
  /// [ownerId] & [plotName] & [adminId] ใช้สำหรับ trigger notification
  Future<void> rejectPlot(
    String plotId,
    String reason, {
    String? ownerId,
    String? plotName,
    String? adminId,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.adminReject(plotId),
        data: {'reason': reason},
      );
    } on ApiException catch (e) {
      throw Exception(
        'ปฏิเสธไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }

    // Trigger notification → แจ้ง User เจ้าของแปลง (พร้อมเหตุผล)
    if (ownerId != null) {
      await _triggerService.onPlotRejected(
        plotId: plotId,
        plotName: plotName ?? 'แปลง',
        userId: ownerId,
        rejectedBy: adminId ?? 'admin',
        reason: reason,
      );
    }
  }

  // ==================== User Management ====================

  /// All users in the admin's territory. The endpoint pages at 20 by
  /// default, so pages are fetched until the reported total is reached.
  Future<List<UserModel>> getUsers({String? status, String? province}) async {
    const pageSize = 100;
    const maxPages = 20;
    final users = <UserModel>[];
    try {
      for (var page = 1; page <= maxPages; page++) {
        final response = await _apiClient.get(
          ApiEndpoints.adminUsers,
          queryParameters: {
            'page': page,
            'limit': pageSize,
            if (status != null) 'status': status,
            if (province != null) 'province': province,
          },
        );
        final body = response.data;
        final list = body is List ? body : (body['data'] as List? ?? const []);
        users.addAll(list.map((j) => UserModel.fromJson(Map<String, dynamic>.from(j))));
        final total = body is Map
            ? (body['total'] ?? body['meta']?['total']) as num?
            : null;
        if (list.length < pageSize || total == null || users.length >= total) break;
      }
      return users;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลสมาชิกได้: $e');
    }
  }

  /// Get user detail
  Future<UserModel> getUserDetail(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.adminUsers}/$userId',
      );
      return UserModel.fromJson(response.data);
    } on ApiException catch (e) {
      throw Exception(
        'ไม่สามารถดึงข้อมูลผู้ใช้ได้: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Approve user membership to community enterprise
  Future<void> approveUserMembership(String userId, {String? adminId}) async {
    try {
      await _apiClient.post('${ApiEndpoints.adminUsers}/$userId/approve');
    } on ApiException catch (e) {
      throw Exception(
        'อนุมัติไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }

    // Log Audit
    _auditService.logAction(
      action: 'APPROVE_USER',
      resourceType: 'USER',
      resourceId: userId,
      details: 'อนุมัติสมาชิกเข้ากลุ่ม',
    );

    // Trigger notification → แจ้ง User
    await _triggerService.onUserApproved(
      userId: userId,
      approvedBy: adminId ?? 'admin',
    );
  }

  /// Update user information (Admin Edit)
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.adminUsers}/$userId',
        data: data,
      );
      return UserModel.fromJson(response.data); // Return updated user
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        throw Exception(e.serverMessage ?? 'ข้อมูลไม่ถูกต้อง');
      }
      throw Exception(
        'แก้ไขข้อมูลไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Reject user membership
  Future<void> rejectUserMembership(String userId, String reason, {String? adminId}) async {
    try {
      await _apiClient.post(
        '${ApiEndpoints.adminUsers}/$userId/reject',
        data: {'reason': reason},
      );
    } on ApiException catch (e) {
      throw Exception(
        'ปฏิเสธไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }

    // Log Audit
    _auditService.logAction(
      action: 'REJECT_USER',
      resourceType: 'USER',
      resourceId: userId,
      details: 'ปฏิเสธสมาชิก: $reason',
    );

    // Trigger notification → แจ้ง User (พร้อมเหตุผล)
    await _triggerService.onUserRejected(
      userId: userId,
      rejectedBy: adminId ?? 'admin',
      reason: reason,
    );
  }

  /// Assign users to admin's territory (SuperAdmin only)
  Future<void> assignUsersToAdmin(String adminId, List<String> userIds) async {
    try {
      await _apiClient.patch(
        '/admin/$adminId/assign-users',
        data: {'userIds': userIds},
      );
    } on ApiException catch (e) {
      throw Exception(
        'มอบหมายไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Submit feedback for a specific GAP category
  /// TODO: BUG-??? - Verify endpoint exists in Swagger before production (2026-01-28)
  Future<void> submitGapFeedback({
    required String plotId,
    required String categoryKey,
    required String message,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.adminGapFeedback,
        data: {'plotId': plotId, 'category': categoryKey, 'message': message},
      );

      // Log Audit on Success
      _auditService.logAction(
        action: 'GAP_FEEDBACK',
        resourceType: 'GAP',
        resourceId: plotId,
        details: 'หมวด $categoryKey: $message',
      );
    } on ApiException catch (e) {
      throw Exception(
        'ส่ง Feedback ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Get user details
  Future<UserModel> getUserDetails(String userId) async {
    try {
      // Try standard endpoint instead of admin specific one (which returns 404)
      final response = await _apiClient.get(
        ApiEndpoints.user(userId),
      );
      return UserModel.fromJson(response.data);
    } on ApiException catch (e) {
      throw Exception(
        'ดึงข้อมูลผู้ใช้ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Admin override update plot geometry
  /// TODO: BUG-??? - Verify endpoint exists in Swagger before production (2026-01-28)
  Future<void> adminUpdatePlot(
    String plotId,
    Map<String, dynamic> geometry,
  ) async {
    try {
      await _apiClient.put(
        ApiEndpoints.adminPlotGeometry(plotId),
        data: {'geometry': geometry},
      );

      // Log Audit on Success
      _auditService.logAction(
        action: 'UPDATE_PLOT',
        resourceType: 'PLOT',
        resourceId: plotId,
        details: 'Admin Override Geometry',
      );
    } on ApiException catch (e) {
      throw Exception(
        'แก้ไขแปลงไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }
  // ============ TRACEABILITY (Admin) ============

  /// Update traceability lot (e.g. set exported status)
  Future<void> updateTraceability(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _apiClient.patch(ApiEndpoints.traceability(id), data: data);
      
      // Log Audit
      _auditService.logAction(
        action: 'UPDATE_TRACEABILITY',
        resourceType: 'TRACEABILITY',
        resourceId: id,
        details: 'แก้ไขข้อมูลการตรวจสอบย้อนกลับ',
      );
    } on ApiException catch (e) {
      throw Exception(
        'แก้ไข Traceability ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Delete traceability lot (Soft Delete)
  Future<void> deleteTraceability(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.traceability(id));
      
      // Log Audit
      _auditService.logAction(
        action: 'DELETE_TRACEABILITY',
        resourceType: 'TRACEABILITY',
        resourceId: id,
        details: 'ลบข้อมูลการตรวจสอบย้อนกลับ',
      );
    } on ApiException catch (e) {
      throw Exception(
        'ลบ Traceability ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  // ==================== NEW FEATURES (Admin/Super Admin) ====================

  /// Upload Profile Photo
  Future<String> uploadProfilePhoto(File file) async {
    return uploadFile(file, endpoint: '/admin/profile/photo');
  }

  /// Generic File Upload
  Future<String> uploadFile(File file, {String endpoint = '/upload'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _apiClient.post(
        endpoint,
        data: formData,
      );

      // Backend returns { "url": "...", "filename": "..." }
      return response.data['url'];
    } on ApiException catch (e) {
      throw Exception('อัพโหลดไฟล์ไม่สำเร็จ: ${e.message}');
    }
  }

  /// Get Gap Analytics
  Future<GapAnalytics> getGapAnalytics({
    String? region,
    String? province,
    String? district,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (region != null) queryParams['region'] = region;
      if (province != null) queryParams['province'] = province;
      if (district != null) queryParams['district'] = district;

      final response = await _apiClient.get(
        '/admin/gap-analytics',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return GapAnalytics.fromJson(response.data);
    } catch (e) {
      // If error, return empty/zero data instead of fake mock data
      return GapAnalytics(
        totalPlots: 0,
        plotsWithGap: 0,
        completionRate: 0.0,
      );
    }
  }

  /// Get User Trends
  Future<List<UserTrendsData>> getUserTrends({
    required String period, // 7d, 30d
    required String metric, // USER_REGISTRATION
  }) async {
    try {
      final response = await _apiClient.get(
        '/admin/statistics/trends',
        queryParameters: {
          'period': period,
          'metric': metric,
        },
      );
      
      final list = (response.data['data'] ?? []) as List;
      return list.map((e) => UserTrendsData.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get Messages (Inbox/Sent)
  Future<List<Message>> getMessages({required String type}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminMessages, // Use constant
        queryParameters: {'type': type},
      );
      
      final list = (response.data['data'] ?? []) as List;
      return list.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Send Message
  Future<void> sendMessage({
    required String recipientId,
    required String subject,
    required String message,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.adminMessages, // Use constant
        data: {
          'recipientId': recipientId,
          'subject': subject,
          'message': message,
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw Exception('คุณสามารถส่งข้อความได้เฉพาะ Admin ในพื้นที่เดียวกันเท่านั้น');
      }
      throw Exception('ส่งข้อความไม่สำเร็จ: ${e.message}');
    }
  }

  /// Reply to Message
  Future<void> replyMessage({
    required String messageId,
    required String message,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.adminMessageReply(messageId),
        data: {'message': message},
      );
    } on ApiException catch (e) {
      throw Exception(
        'ตอบกลับไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  // Chat Features (Unread Count & Read Status)

  /// Get Conversation List with Unread Counts
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminConversations);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Conversation.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get Global Unread Count
  Future<int> getUnreadTotal() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminUnreadTotal);
      return response.data['totalUnread'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark messages from sender as Read
  Future<void> markAsRead(String senderId) async {
    try {
      await _apiClient.post(
        ApiEndpoints.adminMarkRead,
        data: {'senderId': senderId},
      );
    } catch (e) {
      // Ignore error for optimistic UI updates, or log it
      debugPrint('Mark as read failed: $e');
    }
  }
  /// Get PDPA Logs
  Future<List<PdpaLog>> getPdpaLogs() async {
    try {
      final response = await _apiClient.get('/admin/pdpa-logs');
      final list = (response.data['data'] ?? []) as List;
      return list.map((e) => PdpaLog.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
