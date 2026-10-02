
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
      id: '${json['id']}',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'UNREAD',
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
      sender: UserModel.fromJson(json['sender'] as Map<String, dynamic>),
      recipient: json['recipient'] != null
          ? UserModel.fromJson(json['recipient'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isUnread => status.toUpperCase() == 'UNREAD';

  static final _image = RegExp(r'!\[[^\]]*\]\((\S+?)\)');

  /// Text without the markdown image links staff attach to messages.
  String get text => message.replaceAll(_image, '').trim();

  /// Image URLs attached as markdown links.
  List<String> get images => [for (final m in _image.allMatches(message)) m.group(1)!];

  /// One-line preview for conversation lists.
  String get preview {
    final t = text.replaceAll(RegExp(r'\s+'), ' ');
    if (t.isNotEmpty) return t;
    return images.isNotEmpty ? 'ส่งรูปภาพ' : subject;
  }
}
