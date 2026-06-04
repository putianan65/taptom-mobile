import 'message_model.dart';
import 'user_model.dart';

class Conversation {
  final UserModel partner;
  final Message? lastMessage;
  final int unreadCount;

  Conversation({
    required this.partner,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      partner: UserModel.fromJson(json['partner'] as Map<String, dynamic>),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
