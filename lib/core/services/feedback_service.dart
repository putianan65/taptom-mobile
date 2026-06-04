import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class FeedbackService {
  final ApiClient _client = ApiClient();

  /// Submit or update app rating
  Future<void> submitRating({
    required int rating,
    String? feedback,
    String? appVersion,
    String? platform,
    String? deviceModel,
  }) async {
    try {
      await _client.post(
        ApiEndpoints.rateApp,
        data: {
          'rating': rating,
          if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
          if (appVersion != null) 'appVersion': appVersion,
          if (platform != null) 'platform': platform,
          if (deviceModel != null) 'deviceModel': deviceModel,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user's rating
  Future<Map<String, dynamic>?> getMyRating() async {
    try {
      final response = await _client.get(ApiEndpoints.myRating);
      if (response.data == null || response.data == '') return null;
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // If 404 or empty, return null
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      return null; // Fail safe
    }
  }

  /// Get public rating statistics
  Future<Map<String, dynamic>> getRatingStats() async {
    try {
      final response = await _client.get(ApiEndpoints.ratingStats);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'averageRating': 0.0, 'distribution': []};
    }
  }
}
