import '../../../core/networking/api_client.dart';
import 'chat_models.dart';

/// What came back from sending a message.
class ChatReply {
  const ChatReply({required this.conversationId, required this.message});

  final int conversationId;
  final ChatMessage message;
}

class ChatRepository {
  const ChatRepository(this._api);

  final ApiClient _api;

  /// Sends a message. Omitting [conversationId] starts a new conversation.
  Future<ChatReply> send(String message, {int? conversationId}) async {
    final body = await _api.post('/chat', body: {
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
    });

    return ChatReply(
      conversationId: body['conversation_id'] as int,
      message: ChatMessage.fromJson(body['reply'] as Map<String, dynamic>),
    );
  }

  Future<List<Conversation>> listConversations() async {
    // The endpoint returns a bare array, which ApiClient cannot decode into
    // a map, so this one goes through the raw list helper.
    final rows = await _api.getList('/conversations');
    return rows
        .map((r) => Conversation.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> readConversation(int id) async {
    final body = await _api.get('/conversations/$id');
    final messages = body['messages'] as List<dynamic>? ?? [];
    return messages
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteConversation(int id) => _api.delete('/conversations/$id');

  Future<AIStatus> status() async {
    final body = await _api.get('/chat/status');
    return AIStatus.fromJson(body);
  }
}