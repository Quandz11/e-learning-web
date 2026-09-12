import 'dart:async';
import 'package:e_learning_mobile/features/chat/data/chat_repository.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  const ChatState({
    this.conversation,
    required this.messages,
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  final ChatConversation? conversation;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  ChatState copyWith({
    ChatConversation? conversation,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  final currentUserId = ref.watch(profileControllerProvider).profile?.id;
  return ChatController(
    ref.watch(chatRepositoryProvider),
    currentUserId: currentUserId,
  );
});

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repository, {this.currentUserId})
      : super(const ChatState(messages: [], isLoading: true)) {
    load();
  }

  final ChatRepository _repository;
  final String? currentUserId;
  StreamSubscription<ChatMessage>? _messageSubscription;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    if (state.conversation != null) {
      _repository.signalR?.leaveConversation(state.conversation!.id);
    }
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversation = await _repository.getOrCreateSupportConversation(
        currentUserId: currentUserId,
      );
      final messages = await _repository.getMessages(
        conversation.id,
        currentUserId: currentUserId,
      );
      state = state.copyWith(
        conversation: conversation,
        messages: messages,
        isLoading: false,
      );
      _repository.markAsRead(conversation.id).ignore();
      _setupSignalR(conversation.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupSignalR(String conversationId) {
    final signalR = _repository.signalR;
    if (signalR == null) return;

    signalR.connect(currentUserId: currentUserId).then((_) {
      signalR.joinConversation(conversationId);
    });

    _messageSubscription?.cancel();
    _messageSubscription = signalR.onReceiveMessage.listen((incoming) {
      if (incoming.conversationId.isNotEmpty &&
          incoming.conversationId != conversationId) {
        return;
      }
      final existingIndex = state.messages.indexWhere((m) => m.id == incoming.id);
      if (existingIndex >= 0) return;

      final isMe = incoming.senderId == currentUserId;
      final newMsg = incoming.copyWith(isMe: isMe);

      state = state.copyWith(
        messages: [...state.messages, newMsg],
      );
      _repository.markAsRead(conversationId).ignore();
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.conversation == null || state.isSending) return;

    final trimmed = text.trim();
    final tempMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversation!.id,
      senderId: currentUserId ?? 'me',
      senderName: 'Bạn',
      content: trimmed,
      sentAt: DateTime.now(),
      isRead: false,
      isMe: true,
    );

    state = state.copyWith(
      messages: [...state.messages, tempMsg],
      isSending: true,
    );

    try {
      final sent = await _repository.sendMessage(
        conversationId: state.conversation!.id,
        content: trimmed,
        currentUserId: currentUserId,
      );
      final updated = state.messages.map((m) {
        if (m.id == tempMsg.id) return sent.copyWith(isMe: true);
        return m;
      }).toList();
      state = state.copyWith(messages: updated, isSending: false);
    } catch (e) {
      state = state.copyWith(isSending: false);
    }
  }
}
