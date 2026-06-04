/// Model representing a single chat message
class ChatMessage {
  final String id;
  final String content;
  final String? imagePath;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    this.imagePath,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? imagePath,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Factory for creating a loading placeholder message from AI
  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  /// Map conversion for Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'imagePath': imagePath,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      content: map['content'],
      imagePath: map['imagePath'],
      isUser: map['isUser'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
