import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Service for public traceability lookup (no auth required)
/// Calls GET /traceability/:lotNumber to retrieve full farm-to-fork report
class TraceabilityService {
  final ApiClient _api = ApiClient();

  /// Fetch full traceability report by lot number
  /// Returns aggregated data: Plot, Farmer, GAP, Chemicals, Harvest, GeoJSON
  Future<Map<String, dynamic>> getTraceabilityReport(String lotNumber) async {
    try {
      final response = await _api.get(ApiEndpoints.traceability(lotNumber));
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      // Handle wrapped response { data: {...} }
      if (data is Map && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }

      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('TraceabilityService Error: $e');
      rethrow;
    }
  }
}
