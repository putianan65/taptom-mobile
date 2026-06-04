
import 'user_model.dart';

class Message {
  final String id;
  final String subject;
  final String message;
  final String status; // UNREAD, READ
  final DateTime createdAt;
  final UserModel sender;
  final UserModel? recipient;

  Message({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.sender,
    this.recipient,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'UNREAD',
      createdAt: DateTime.parse(json['createdAt'] as String),
      sender: UserModel.fromJson(json['sender'] as Map<String, dynamic>),
      recipient: json['recipient'] != null
          ? UserModel.fromJson(json['recipient'] as Map<String, dynamic>)
          : null,
    );
  }
}
