import 'dart:async';
import 'package:e_learning_mobile/features/chat/data/chat_repository.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import '../../data/message_merge.dart';
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
  final currentUserId = ref.watch(sessionControllerProvider.select((s) => s.session?.userId));
  return ChatController(
    ref.watch(chatRepositoryProvider),
    currentUserId: currentUserId,
  );
});

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repository, {this.currentUserId})
      : super(const ChatState(messages: [], isLoading: true)) {
    if (currentUserId != null) { load(); }
    else { state = const ChatState(messages: []); }
  }

  final ChatRepository _repository;
  final String? currentUserId;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<void>? _reconnectSubscription;
  int _loadVersion = 0;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _reconnectSubscription?.cancel();
    final id = state.conversation?.id;
    if (id != null) _repository.signalR?.leaveConversation(id);
    super.dispose();
  }

  Future<void> load() async {
    if (currentUserId == null) return;
    final version = ++_loadVersion;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversation = await _repository.getOrCreateSupportConversation(currentUserId: currentUserId);
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(conversation: conversation);
      await _setupSignalR(conversation.id);
      final messages = await _repository.getMessages(conversation.id, currentUserId: currentUserId);
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(messages: mergeMessages(messages, state.messages, currentUserId: currentUserId), isLoading: false);
      _repository.markAsRead(conversation.id).ignore();
    } catch (_) {
      if (mounted && version == _loadVersion) state = state.copyWith(isLoading: false, error: 'Kh?ng th? t?i cu?c tr? chuy?n.');
    }
  }

  Future<void> _setupSignalR(String conversationId) async {
    final signalR = _repository.signalR;
    if (signalR == null) return;
    await _messageSubscription?.cancel();
    await _reconnectSubscription?.cancel();
    if (!mounted) return;
    _messageSubscription = signalR.onReceiveMessage.listen((incoming) {
      if (!mounted || incoming.conversationId != conversationId) return;
      state = state.copyWith(messages: mergeMessages(state.messages, [incoming], currentUserId: currentUserId));
      _repository.markAsRead(conversationId).ignore();
    });
    _reconnectSubscription = signalR.onReconnected.listen((_) => load());
    await signalR.connect(currentUserId: currentUserId);
    if (mounted) await signalR.joinConversation(conversationId);
  }

  Future<void> sendMessage(String text, {String? clientMessageId}) async {
    final conversationId = state.conversation?.id;
    if (text.trim().isEmpty || conversationId == null || state.isSending || currentUserId == null) return;
    final correlation = clientMessageId ?? newClientMessageId();
    final pending = ChatMessage(id: 'temp_$correlation', clientMessageId: correlation,
      conversationId: conversationId, senderId: currentUserId!, senderName: 'B?n',
      content: text.trim(), sentAt: DateTime.now(), isRead: false, isMe: true, delivery: 'sending');
    state = state.copyWith(messages: mergeMessages(state.messages, [pending], currentUserId: currentUserId), isSending: true, clearError: true);
    try {
      final sent = await _repository.sendMessage(conversationId: conversationId, content: pending.content,
        currentUserId: currentUserId, clientMessageId: correlation);
      if (!mounted) return;
      state = state.copyWith(messages: mergeMessages(state.messages, [sent.copyWith(clientMessageId: correlation)],
        currentUserId: currentUserId), isSending: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(messages: mergeMessages(state.messages, [pending.copyWith(delivery: 'failed')],
        currentUserId: currentUserId), isSending: false);
    }
  }
}
