import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../locator.dart';
import 'notification_trigger_service.dart';

/// Service for managing GAP form data via API
class GapService {
  final ApiClient _apiClient = ApiClient();

  /// Get all GAP data for a plot
  Future<Map<String, dynamic>?> getGapData(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.gap(plotId));
      if (response.data == null || response.data == '') return null;
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      debugPrint('Error getting GAP data: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting GAP data: $e');
      rethrow; // Rethrow to let UI handle it
    }
  }

  // ============ RESET DATA ============

  /// Reset all GAP data for a plot (Soft Delete)
  Future<void> resetGapData(String plotId) async {
    try {
      await _apiClient.post(
        ApiEndpoints.gapReset(plotId),
        data: {'confirm': 'RESET'},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(
          'ไม่สามารถล้างข้อมูลได้: มีล็อตผลผลิตที่ส่งออกแล้ว',
        );
      }
      throw Exception('ล้างข้อมูลไม่สำเร็จ: ${e.message}');
    }
  }

  /// Get GAP compliance dashboard (1.1-1.7 status)
  Future<Map<String, dynamic>> getGapCompliance(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.gapCompliance(plotId));
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      // Silent failure - return empty map
      return {};
    }
  }

  /// Get GAP summary for a plot
  Future<Map<String, dynamic>> getGapSummary(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.gapSummary(plotId));
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      // Silent failure - return empty map
      return {};
    }
  }

  /// Save general info section
  Future<void> saveGeneralInfo(String plotId, Map<String, dynamic> data) async {
    await _apiClient.put(ApiEndpoints.gap(plotId), data: data);
  }

  /// Save management info section
  Future<void> saveManagementInfo(
    String plotId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.put(ApiEndpoints.gap(plotId), data: data);
  }

  /// Save post-harvest info section
  Future<void> savePostHarvestInfo(
    String plotId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.put(ApiEndpoints.gap(plotId), data: data);
  }

  /// Save safety info section
  Future<void> saveSafetyInfo(String plotId, Map<String, dynamic> data) async {
    await _apiClient.put(ApiEndpoints.gap(plotId), data: data);
  }

  /// Get inputs (production factors) for a plot
  Future<List<dynamic>> getInputs(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.inputs(plotId));
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }
      return data as List<dynamic>? ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('Error getting inputs: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting inputs: $e');
      rethrow;
    }
  }

  /// Add new input record
  Future<void> addInput(String plotId, Map<String, dynamic> data) async {
    await _apiClient.post(ApiEndpoints.inputs(plotId), data: data);
  }

  /// Get field activities for a plot
  Future<List<dynamic>> getActivities(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.activities(plotId));
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }
      return data as List<dynamic>? ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('Error getting activities: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting activities: $e');
      rethrow;
    }
  }

  /// Add new field activity
  Future<void> addActivity(String plotId, Map<String, dynamic> data) async {
    await _apiClient.post(ApiEndpoints.activities(plotId), data: data);
  }

  /// Get harvest records for a plot
  Future<List<dynamic>> getHarvests(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.harvests(plotId));
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }
      return data as List<dynamic>? ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('Error getting harvests: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting harvests: $e');
      rethrow;
    }
  }

  /// Add new harvest record
  Future<void> addHarvest(String plotId, Map<String, dynamic> data) async {
    await _apiClient.post(ApiEndpoints.harvests(plotId), data: data);
  }

  /// Get training records for a plot
  Future<List<dynamic>> getTrainings(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.trainings(plotId));
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }
      return data as List<dynamic>? ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('Error getting trainings: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting trainings: $e');
      rethrow;
    }
  }

  /// Add new training record
  Future<void> addTraining(String plotId, Map<String, dynamic> data) async {
    await _apiClient.post(ApiEndpoints.trainings(plotId), data: data);
  }

  /// Get field managements for a plot (same as activities)
  Future<List<dynamic>> getFieldManagements(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.activities(plotId));
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }
      return data as List<dynamic>? ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get post-harvest records for a specific harvest
  Future<List<dynamic>> getPostHarvest(String harvestId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.postHarvest(harvestId),
      );
      // Handle both List (multiple) and Map (single object/paginated) responses
      if (response.data is List) {
        return response.data as List<dynamic>;
      } else if (response.data is Map) {
        final mapData = response.data as Map<String, dynamic>;
        // Check for paginated response { data: [], meta: {} }
        if (mapData.containsKey('data') && mapData['data'] is List) {
          return mapData['data'] as List<dynamic>;
        }
        // Single object returned - wrap in list
        return [response.data];
      }
      return [];
    } catch (e) {
      // Silent failure - return empty list
      return [];
    }
  }

  /// Add new post-harvest record to a harvest
  Future<void> addPostHarvest(
    String harvestId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.post(ApiEndpoints.postHarvest(harvestId), data: data);
  }

  /// Get all post-harvest records for a plot (by getting all harvests first)
  Future<List<dynamic>> getPostHarvestsForPlot(String plotId) async {
    try {
      final harvests = await getHarvests(plotId);
      final List<dynamic> allPostHarvests = [];
      for (final harvest in harvests) {
        // Optimization: usage embedded data if available
        if (harvest['postHarvests'] != null && harvest['postHarvests'] is List) {
          allPostHarvests.addAll(harvest['postHarvests']);
          continue;
        }

        final harvestId = harvest['id']?.toString();
        if (harvestId != null) {
          final postHarvests = await getPostHarvest(harvestId);
          allPostHarvests.addAll(postHarvests);
        }
      }
      return allPostHarvests;
    } catch (e) {
      return [];
    }
  }

  /// Get traceability lots for a plot
  Future<List<dynamic>> getTraceabilityLots(String plotId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.traceabilityLots(plotId));
      final data = response.data;
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'] as List;
      return [];
    } catch (e) {
      debugPrint('getTraceabilityLots error, falling back to harvests: $e');
      // Fallback to harvests if traceability endpoint is unavailable
      return getHarvests(plotId);
    }
  }

  // ============ UPDATE METHODS (PUT) ============

  /// Update existing harvest record
  Future<void> updateHarvest(
    String plotId,
    String harvestId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.put(ApiEndpoints.harvest(plotId, harvestId), data: data);
  }

  /// Update existing field activity
  Future<void> updateActivity(
    String plotId,
    String activityId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.put(ApiEndpoints.activity(plotId, activityId), data: data);
  }

  /// Update existing training record
  Future<void> updateTraining(
    String plotId,
    String trainingId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.put(ApiEndpoints.training(plotId, trainingId), data: data);
  }

  /// Update existing post-harvest record
  Future<void> updatePostHarvest(
    String harvestId,
    String postHarvestId,
    Map<String, dynamic> data,
  ) async {
    await _apiClient.put(
      ApiEndpoints.postHarvestItem(harvestId, postHarvestId),
      data: data,
    );
  }

  // ============ DELETE METHODS ============

  /// Delete general info (Clear section 1)
  Future<void> deleteGeneralInfo(String plotId) async {
    // Attempt standard REST delete, or fallback to reset if not supported
    // For now, assuming DELETE on resource works or we have to use specific logic.
    // If DELETE /gap not supported, we might need a specific endpoint.
    // Trying DELETE first.
    await _apiClient.delete(ApiEndpoints.gap(plotId));
  }

  /// Delete input record
  Future<void> deleteInput(String plotId, String id) async {
    await _apiClient.delete(ApiEndpoints.input(plotId, id));
  }

  /// Delete field activity record
  Future<void> deleteActivity(String plotId, String id) async {
    await _apiClient.delete(ApiEndpoints.activity(plotId, id));
  }

  /// Delete harvest record
  Future<void> deleteHarvest(String plotId, String id) async {
    await _apiClient.delete(ApiEndpoints.harvest(plotId, id));
  }

  /// Delete post-harvest record
  Future<void> deletePostHarvest(String harvestId, String id) async {
    await _apiClient.delete(ApiEndpoints.postHarvestItem(harvestId, id));
  }

  /// Delete training record
  Future<void> deleteTraining(String plotId, String id) async {
    await _apiClient.delete(ApiEndpoints.training(plotId, id));
  }

  // ============ ADMIN NOTIFICATION ============

  /// Notify admin when user edits a record
  Future<void> notifyAdminOnEdit({
    required String plotId,
    required String formType,
    required String recordId,
    List<String>? adminIds, // ✅ เพิ่ม parameter นี้ (optional with default null)
  }) async {
    try {
      final triggerService = locator<NotificationTriggerService>();
      await triggerService.onRecordEdited(
        plotId: plotId,
        formType: formType,
        recordId: recordId,
        adminIds: adminIds ?? [], // ✅ ส่ง empty list ถ้าไม่มีค่า
      );
    } catch (e) {
      // Silently fail - notification is not critical
      debugPrint('Trigger notification failed: $e');
    }
  }
}
