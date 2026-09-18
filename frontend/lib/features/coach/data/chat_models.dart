/// One message in a conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.pending = false,
  });

  final int id;

  /// 'user' or 'assistant'.
  final String role;

  final String content;
  final DateTime createdAt;

  /// True for a message shown optimistically before the server confirms it.
  /// Lets the UI display what was typed immediately rather than after the
  /// round trip.
  final bool pending;

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        role: json['role'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// A local message that has no server id yet.
  factory ChatMessage.local(String content) => ChatMessage(
        id: -DateTime.now().microsecondsSinceEpoch,
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
        pending: true,
      );
}

/// A conversation, without its messages.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final DateTime updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        title: json['title'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

/// Whether the AI is reachable, so the UI can say so before a send.
class AIStatus {
  const AIStatus({
    required this.provider,
    required this.model,
    required this.available,
  });

  final String provider;
  final String model;
  final bool available;

  factory AIStatus.fromJson(Map<String, dynamic> json) => AIStatus(
        provider: json['provider'] as String,
        model: json['model'] as String,
        available: json['available'] as bool,
      );
}