import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../data/models/audit_log_model.dart';
import 'package:flutter/foundation.dart';

/// Audit service for logging admin actions
class AuditService {
  final ApiClient _apiClient = ApiClient();

  /// Log an admin action
  Future<void> logAction({
    required String action,
    String? resourceType,
    String? resourceId,
    String? details,
  }) async {
    try {
      // Don't await this to keep UI responsive
      // But in production, we might want to ensure it's sent
      _apiClient.post(
        ApiEndpoints.adminAuditLogs,
        data: {
          'action': action,
          'resourceType': resourceType,
          'resourceId': resourceId,
          'details': details,
        }
      ).catchError((e) {
        debugPrint('Failed to log audit action: $e');
      });
    } catch (e) {
      debugPrint('Failed to initiate audit log: $e');
    }
  }

  /// Fetch audit logs
  Future<List<AuditLog>> getAuditLogs({
    int limit = 50,
    int offset = 0,
    String? adminId,
    String? action,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      
      if (adminId != null) queryParams['adminId'] = adminId;
      if (action != null) queryParams['action'] = action;

      final response = await _apiClient.get(
        ApiEndpoints.adminAuditLogs,
        queryParameters: queryParams,
      );

      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      return (data as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
      throw Exception('ไม่สามารถดึงข้อมูล Audit Logs ได้');
    }
  }

  /// Get audit log by ID
  Future<AuditLog?> getAuditLog(String id) async {
    // TODO: Implement fetching from backend if needed
    return null;
  }

  /// Delete audit log
  Future<void> deleteAuditLog(String id) async {
    // TODO: Implement deletion on backend
  }

  /// Clear audit logs (admin only)
  Future<void> clearAuditLogs() async {
    // TODO: Implement clearing on backend
  }
}
