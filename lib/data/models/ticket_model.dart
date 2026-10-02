
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
      id: '${json['id']}',
      message: '${json['message'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
      author: UserModel.fromJson(Map<String, dynamic>.from((json['author'] ?? json['user'] ?? const {'id': ''}) as Map)),
    );
  }
}

class Ticket {
  final String id;
  final String subject;
  final String message;
  final String status; // OPEN, IN_PROGRESS, RESOLVED, CLOSED
  final String priority; // HIGH, MEDIUM, LOW
  final String? category; // BUG, PLOT, ACCOUNT, OTHER ...
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
    this.category,
    required this.createdAt,
    this.updatedAt,
    required this.user,
    required this.replies,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: '${json['id']}',
      subject: '${json['subject'] ?? ''}',
      message: '${json['message'] ?? ''}',
      category: json['category']?.toString(),
      status: json['status'] as String? ?? 'OPEN',
      priority: json['priority'] as String? ?? 'MEDIUM',
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}')?.toLocal(),
      user: UserModel.fromJson(Map<String, dynamic>.from((json['user'] ?? const {'id': ''}) as Map)),
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((e) => TicketReply.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
