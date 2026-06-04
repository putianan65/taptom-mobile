
import 'user_model.dart';

class TicketReply {
  final String id;
  final String message;
  final DateTime createdAt;
  final UserModel author;

  TicketReply({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.author,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: json['id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}

class Ticket {
  final String id;
  final String subject;
  final String message;
  final String status; // OPEN, IN_PROGRESS, RESOLVED, CLOSED
  final String priority; // HIGH, MEDIUM, LOW
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserModel user;
  final List<TicketReply> replies;

  Ticket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    required this.user,
    required this.replies,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'OPEN',
      priority: json['priority'] as String? ?? 'MEDIUM',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((e) => TicketReply.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
