import 'package:flutter/foundation.dart';

import '../../data/models/audit_log_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Reads and writes the staff audit trail.
class AuditService {
  final ApiClient _apiClient = ApiClient();

  /// Records a staff action. Fire and forget: a failed write must never
  /// block the action it describes.
  void logAction({
    required String action,
    String? resourceType,
    String? resourceId,
    String? details,
  }) {
    _apiClient.post(
      ApiEndpoints.adminAuditLogs,
      data: {
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'details': details,
      },
    ).then<void>((_) {}, onError: (Object e) => debugPrint('Audit write failed: $e'));
  }

  /// One page of the trail, newest first.
  Future<List<AuditLog>> getAuditLogs({int page = 1, int limit = 20, String? action}) async {
    final response = await _apiClient.get(
      ApiEndpoints.adminAuditLogs,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (action != null) 'action': action,
      },
    );
    final body = response.data;
    final list = body is List ? body : (body is Map ? body['data'] : null);
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map) AuditLog.fromJson(Map<String, dynamic>.from(e)),
    ];
  }
}
