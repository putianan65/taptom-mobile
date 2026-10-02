
import '../network/api_client.dart';
import '../../data/models/ticket_model.dart';

class SupportService {
  final ApiClient _apiClient = ApiClient();

  /// Get Tickets
  Future<List<Ticket>> getTickets({
    String status = 'ALL',
    String? userId, // ✅ Re-enabled per Backend Update
  }) async {
    try {
      final queryParams = <String, dynamic>{'status': status};
      if (userId != null) queryParams['userId'] = userId;

      final response = await _apiClient.get(
        '/support/tickets',
        queryParameters: queryParams,
      );

      final list = (response.data['data'] ?? []) as List;
      return list.map((e) => Ticket.fromJson(e)).toList();
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลตั๋วได้: $e');
    }
  }

  /// One ticket with its replies.
  Future<Ticket> getTicket(String id) async {
    final response = await _apiClient.get('/support/tickets/$id');
    final body = response.data;
    final map = body is Map && body['data'] is Map ? body['data'] : body;
    return Ticket.fromJson(Map<String, dynamic>.from(map as Map));
  }

  /// Opens a ticket. [category] follows the API's CreateSupportTicketDto.
  Future<Ticket> createTicket({
    required String subject,
    required String message,
    required String category,
    String priority = 'MEDIUM',
  }) async {
    final response = await _apiClient.post(
      '/support/tickets',
      data: {'subject': subject, 'message': message, 'category': category, 'priority': priority},
    );
    final body = response.data;
    final map = body is Map && body['data'] is Map ? body['data'] : body;
    return Ticket.fromJson(Map<String, dynamic>.from(map as Map));
  }

  /// Reply to Ticket
  Future<void> replyToTicket({
    required String ticketId,
    required String message,
  }) async {
    try {
      await _apiClient.post(
        '/support/tickets/$ticketId/reply', // Using confirmed path structure
        data: {'message': message},
      );
    } catch (e) {
      throw Exception('ตอบกลับไม่สำเร็จ: $e');
    }
  }

  /// Update Ticket Status (New Backend Feature)
  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _apiClient.patch(
        '/support/tickets/$ticketId/status',
        data: {'status': status},
      );
    } catch (e) {
      throw Exception('อัพเดทสถานะไม่สำเร็จ: $e');
    }
  }

  /// Close Ticket (Wrapper for update status)
  Future<void> closeTicket(String ticketId) async {
    await updateTicketStatus(ticketId, 'CLOSED');
  }
}
