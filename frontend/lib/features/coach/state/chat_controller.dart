import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(apiClientProvider)),
);

/// The list of past conversations. Refreshed after each new one starts.
final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(chatRepositoryProvider).listConversations(),
);

/// Opening questions for the empty state and the dashboard.
///
/// Kept separate from ChatState so it survives starting a new conversation
/// and is fetched once rather than on every message.
final suggestionsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(chatRepositoryProvider).suggestions(),
);

class ChatState {
  const ChatState({
    this.conversationId,
    this.messages = const [],
    this.sending = false,
    this.loading = false,
    this.error,
  });

  /// Null means nothing has been sent yet: a new conversation.
  final int? conversationId;

  final List<ChatMessage> messages;
  final bool sending;
  final bool loading;

  /// Last failure, shown inline. Cleared on the next attempt.
  final String? error;

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({
    int? conversationId,
    List<ChatMessage>? messages,
    bool? sending,
    bool? loading,
    String? error,
  }) =>
      ChatState(
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        loading: loading ?? this.loading,
        error: error,
      );
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() {
    // Resets when the session changes, so one user's conversation never
    // stays on screen for another.
    ref.watch(authControllerProvider);
    return const ChatState();
  }

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  /// Clears the screen for a fresh conversation.
  void startNew() => state = const ChatState();

  /// Loads an existing conversation's messages.
  Future<void> open(int conversationId) async {
    state = ChatState(conversationId: conversationId, loading: true);
    try {
      final messages = await _repo.readConversation(conversationId);
      state = ChatState(conversationId: conversationId, messages: messages);
    } catch (e) {
      state = ChatState(conversationId: conversationId, error: e.toString());
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    // Shown immediately so the screen responds to typing rather than to
    // the network. Replaced by the server's copy when the reply lands.
    final optimistic = ChatMessage.local(trimmed);
    state = state.copyWith(
      messages: [...state.messages, optimistic],
      sending: true,
    );

    try {
      final reply = await _repo.send(
        trimmed,
        conversationId: state.conversationId,
      );

      state = ChatState(
        conversationId: reply.conversationId,
        messages: [
          ...state.messages.where((m) => m.id != optimistic.id),
          ChatMessage(
            id: optimistic.id,
            role: 'user',
            content: trimmed,
            createdAt: optimistic.createdAt,
          ),
          reply.message,
        ],
      );

      // A new conversation should appear in the sidebar straight away.
      ref.invalidate(conversationsProvider);
    } catch (e) {
      // The message stays on screen so it can be retried without retyping.
      state = state.copyWith(sending: false, error: e.toString());
    }
  }

  Future<void> deleteConversation(int id) async {
    await _repo.deleteConversation(id);
    ref.invalidate(conversationsProvider);
    if (state.conversationId == id) startNew();
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);
    