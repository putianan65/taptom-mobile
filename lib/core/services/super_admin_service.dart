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
    } on DioException catch (e) {
      throw Exception(
        'ดึงข้อมูล Admin ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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
    } on DioException catch (e) {
      throw Exception(
        'ดึงข้อมูลผู้ใช้ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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
    } on DioException catch (e) {
      throw Exception(
        'สร้าง Admin ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  /// Delete Admin (Soft delete)
  Future<void> deleteAdmin(String adminId) async {
    try {
      await _apiClient.delete(ApiEndpoints.adminDelete(adminId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('ไม่สามารถลบบัญชีของตัวเองได้');
      }
      throw Exception(
        'ลบ Admin ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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
    } on DioException catch (e) {
      throw Exception(
        'ย้าย User ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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
    } on DioException catch (e) {
      throw Exception(
        'มอบหมายไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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
    } on DioException catch (e) {
      throw Exception(
        'เปลี่ยนสิทธิ์ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  /// Restore Deleted User
  Future<void> restoreUser(String userId) async {
    try {
      await _apiClient.patch('/users/$userId/restore');
    } on DioException catch (e) {
      throw Exception(
        'กู้คืนผู้ใช้ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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

  /// Get Audit Logs
  Future<List<dynamic>> getAuditLogs({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/admin/audit-logs',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
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

  // ==================== User Actions ====================

  /// Delete User (Super Admin can delete any user)
  Future<void> deleteUser(String userId) async {
    try {
      await _apiClient.delete(ApiEndpoints.user(userId));
    } on DioException catch (e) {
      throw Exception(
        'ลบผู้ใช้ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  // ==================== Dashboard & Analytics ====================

  /// Get System Stats for Dashboard (parallel calls)
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final results = await Future.wait([
        _apiClient.get(ApiEndpoints.users),
        _apiClient.get(ApiEndpoints.adminList),
        _apiClient.get(ApiEndpoints.plotSummary),
      ], eagerError: false);

      // Parse users count
      final usersData = results[0].data;
      int totalUsers = 0;
      int pendingUsers = 0;
      if (usersData is Map && usersData.containsKey('data')) {
        final userList = usersData['data'] as List? ?? [];
        totalUsers = userList.length;
        pendingUsers = userList
            .where((u) => u['membershipStatus'] == 'PENDING')
            .length;
      } else if (usersData is List) {
        totalUsers = usersData.length;
        pendingUsers = usersData
            .where((u) => u['membershipStatus'] == 'PENDING')
            .length;
      }

      // Parse admins count
      final adminsData = results[1].data;
      int totalAdmins = 0;
      if (adminsData is Map && adminsData.containsKey('data')) {
        totalAdmins = (adminsData['data'] as List?)?.length ?? 0;
      } else if (adminsData is List) {
        totalAdmins = adminsData.length;
      }

      // Parse plot summary
      final plotData = results[2].data;
      int totalPlots = 0;
      int pendingPlots = 0;
      if (plotData is Map) {
        totalPlots = plotData['totalPlots'] ?? plotData['total'] ?? 0;
        pendingPlots = plotData['pendingPlots'] ?? plotData['pending'] ?? 0;
      }

      return {
        'totalUsers': totalUsers,
        'pendingUsers': pendingUsers,
        'totalAdmins': totalAdmins,
        'totalPlots': totalPlots,
        'pendingPlots': pendingPlots,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'pendingUsers': 0,
        'totalAdmins': 0,
        'totalPlots': 0,
        'pendingPlots': 0,
      };
    }
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

  /// Get Registration Trends
  Future<List<dynamic>> getRegistrationTrends() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminTrends);
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
    } on DioException catch (e) {
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
    } on DioException catch (e) {
      throw Exception(
        'ส่งข้อความไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('ไม่พบข้อความที่ต้องการตอบกลับ');
      } else if (e.response?.statusCode == 403) {
        throw Exception('คุณไม่มีสิทธิ์ตอบกลับข้อความนี้');
      }
      throw Exception(
        'ตอบกลับไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
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
      print('Mark as read failed: $e');
    }
  }
}