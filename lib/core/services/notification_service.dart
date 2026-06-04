import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../data/models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Get notifications with pagination
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead, // Optional filter
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};
      if (isRead != null) {
        queryParams['isRead'] = isRead.toString();
      }

      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: queryParams,
      );

      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Create a notification
  /// รองรับ fields ใหม่: userId, data, actionUrl, createdBy
  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String? userId,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? createdBy,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.notifications,
        data: {
          'title': title,
          'message': message,
          'type': type,
          if (userId != null) 'userId': userId,
          if (data != null) 'data': data,
          if (actionUrl != null) 'actionUrl': actionUrl,
          if (createdBy != null) 'createdBy': createdBy,
          'isRead': false,
        },
      );
    } catch (e) {
      throw Exception('สร้างการแจ้งเตือนไม่สำเร็จ: ${e.toString()}');
    }
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.patch(ApiEndpoints.notificationRead(id));
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
       throw UnimplementedError('Backend API does not support mark all as read yet.');
    } catch (e) {
      // Fail silently
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.notificationDelete(id));
    } catch (e) {
      throw Exception('ไม่สามารถลบการแจ้งเตือนได้');
    }
  }

  /// Get unread count (Helper)
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        queryParameters: {'isRead': 'false', 'limit': 1},
      );
      
      if (response.data is Map && response.data.containsKey('meta')) {
        return response.data['meta']['totalItems'] ?? response.data['meta']['total'] ?? 0;
      } else if (response.data is Map && response.data.containsKey('total')) {
         return response.data['total'] ?? 0;
      }
      
      return 0; 
    } catch (e) {
      return 0;
    }
  }
}
