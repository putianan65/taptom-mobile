import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../data/models/pdpa_log_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart'; // ✅ Added Import

class SuperAdminService {
  final ApiClient _apiClient = ApiClient();

  // ==================== Admin Management ====================

  /// Get list of all Admins
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

  /// Get All Users (Super Admin has global scope)
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.users);
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
      return [];
    } on ApiException catch (e) {
      throw Exception(
        'ดึงข้อมูลผู้ใช้ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Create a new Admin
  Future<Map<String, dynamic>> createAdmin({
    required String phone,
    required String firstName,
    required String lastName,
    required String job,
    required String region,
    String? province,
    String? district,
    String? subDistrict,
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

      if (province != null && province.isNotEmpty) data['province'] = province;
      if (district != null && district.isNotEmpty) data['district'] = district;
      if (subDistrict != null && subDistrict.isNotEmpty)
        data['subDistrict'] = subDistrict;

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

  /// Delete Admin (Soft delete)
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

  /// Assign users to admin's territory
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

  // ==================== User Role Management ====================

  /// Update User Role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _apiClient.patch(
        '/users/$userId/role',
        data: {'role': newRole},
      );
    } on ApiException catch (e) {
      throw Exception(
        'เปลี่ยนสิทธิ์ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Restore Deleted User
  Future<void> restoreUser(String userId) async {
    try {
      await _apiClient.patch('/users/$userId/restore');
    } on ApiException catch (e) {
      throw Exception(
        'กู้คืนผู้ใช้ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  /// Get Deleted Users
  Future<List<dynamic>> getDeletedUsers() async {
    try {
      final response = await _apiClient.get(
        '/users', 
        queryParameters: {'includeDeleted': true}
      );
      final List<dynamic> allUsers = response.data['data'] ?? [];
      return allUsers.where((u) => u['deletedAt'] != null).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== System Logs ====================

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

  // ==================== User Actions ====================

  /// Delete User (Super Admin can delete any user)
  Future<void> deleteUser(String userId) async {
    try {
      await _apiClient.delete(ApiEndpoints.user(userId));
    } on ApiException catch (e) {
      throw Exception(
        'ลบผู้ใช้ไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  // ==================== Dashboard & Analytics ====================

  /// Platform-wide figures for the console home. Each source is fetched
  /// independently so one failing endpoint does not blank the dashboard.
  Future<Map<String, dynamic>> getSystemStats() async {
    Future<dynamic> safe(Future<dynamic> f) async {
      try {
        return (await f).data;
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([
      safe(_apiClient.get(ApiEndpoints.userStats)),
      safe(_apiClient.get(ApiEndpoints.adminList)),
      safe(_apiClient.get(ApiEndpoints.plotSummary)),
      safe(_apiClient.get(ApiEndpoints.adminPlots, queryParameters: {'status': 'PENDING'})),
      safe(_apiClient.get(ApiEndpoints.adminUsers,
          queryParameters: {'status': 'PENDING', 'limit': 1})),
    ]);

    int asInt(dynamic v) => v is num ? v.toInt() : 0;
    int listLength(dynamic body) {
      if (body is List) return body.length;
      if (body is Map) {
        final total = body['total'] ?? body['meta']?['total'];
        if (total is num) return total.toInt();
        if (body['data'] is List) return (body['data'] as List).length;
      }
      return 0;
    }

    final userStats = results[0] is Map ? results[0] as Map : const {};
    final byRole = userStats['byRole'] is Map ? userStats['byRole'] as Map : const {};
    final plotSummary = results[2] is Map ? results[2] as Map : const {};

    return {
      'totalUsers': asInt(userStats['total']),
      'farmers': asInt(byRole['USER']),
      'totalAdmins': results[1] == null ? asInt(byRole['ADMIN']) : listLength(results[1]),
      'activeUsers': asInt(userStats['activeUsers']),
      'recentUsers': asInt(userStats['recentlyCreated'] ?? userStats['recentSignups']),
      'pendingUsers': listLength(results[4]),
      'totalPlots': asInt(plotSummary['totalPlots'] ?? plotSummary['total']),
      'totalArea': (plotSummary['totalArea'] as num?)?.toDouble() ?? 0,
      'riskyPlots': asInt(plotSummary['riskyPlots']),
      'pendingPlots': listLength(results[3]),
    };
  }

  /// Get GAP Analytics (optional province filter)
  Future<Map<String, dynamic>> getGapAnalytics({String? province}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (province != null && province.isNotEmpty) {
        queryParams['province'] = province;
      }
      final response = await _apiClient.get(
        ApiEndpoints.adminGapAnalytics,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};
    } catch (e) {
      return {};
    }
  }

  /// Registration (or plot creation) counts per day.
  Future<List<dynamic>> getRegistrationTrends({
    String period = '7d',
    String metric = 'USER_REGISTRATION',
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminTrends,
        queryParameters: {'period': period, 'metric': metric},
      );
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== File Upload ====================

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

      return response.data['url'];
    } on ApiException catch (e) {
      throw Exception('อัพโหลดไฟล์ไม่สำเร็จ: ${e.message}');
    }
  }

  // ==================== Messaging ====================

  /// Get Messages (Inbox/Sent)
  Future<List<Message>> getMessages({
    String box = 'INBOX',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminMessages,
        queryParameters: {
          'type': box,
          'page': page,
          'limit': limit,
        },
      );
      if (response.data is Map && response.data.containsKey('data')) {
        final list = response.data['data'] as List;
        return list.map((e) => Message.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Send New Message
  Future<void> sendMessage({
    required String recipientId,
    required String subject,
    required String message,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.adminMessages,
        data: {
          'recipientId': recipientId,
          'subject': subject,
          'message': message,
        },
      );
    } on ApiException catch (e) {
      throw Exception(
        'ส่งข้อความไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  // ✅ NEW: Reply to Message
  /// Reply to an existing message in a conversation thread
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
      if (e.isNotFound) {
        throw Exception('ไม่พบข้อความที่ต้องการตอบกลับ');
      } else if (e.statusCode == 403) {
        throw Exception('คุณไม่มีสิทธิ์ตอบกลับข้อความนี้');
      }
      throw Exception(
        'ตอบกลับไม่สำเร็จ: ${e.serverMessage ?? e.message}',
      );
    }
  }

  // ✅ NEW: Chat Features (Unread Count & Read Status)

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
      debugPrint('Mark as read failed: $e');
    }
  }
}