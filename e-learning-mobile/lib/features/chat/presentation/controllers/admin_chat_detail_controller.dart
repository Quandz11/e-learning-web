import 'dart:async';
import 'package:e_learning_mobile/features/chat/data/chat_repository.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import '../../data/message_merge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminChatDetailState {
  const AdminChatDetailState({
    required this.conversation,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  final AdminConversationItem conversation;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  AdminChatDetailState copyWith({
    AdminConversationItem? conversation,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return AdminChatDetailState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final adminChatDetailProvider = StateNotifierProvider.family
    .autoDispose<
      AdminChatDetailController,
      AdminChatDetailState,
      AdminConversationItem
    >((ref, conversation) {
      final currentUserId = ref.watch(
        sessionControllerProvider.select((s) => s.session?.userId),
      );
      return AdminChatDetailController(
        ref.watch(chatRepositoryProvider),
        conversation: conversation,
        currentUserId: currentUserId,
      );
    });

class AdminChatDetailController extends StateNotifier<AdminChatDetailState> {
  AdminChatDetailController(
    this._repository, {
    required AdminConversationItem conversation,
    this.currentUserId,
  }) : super(
         AdminChatDetailState(conversation: conversation, isLoading: true),
       ) {
    if (currentUserId != null) {
      _setupSignalR();
      load();
    }
  }

  final ChatRepository _repository;
  final String? currentUserId;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<void>? _reconnectSubscription;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _reconnectSubscription?.cancel();
    if (state.conversation.type != 'guest') {
      _repository.signalR?.leaveConversation(state.conversation.id);
    }
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<ChatMessage> msgs;
      if (state.conversation.type == 'guest') {
        final gId = state.conversation.guestId ?? state.conversation.id;
        msgs = await _repository.getAdminGuestMessages(gId);
      } else {
        msgs = await _repository.getMessages(
          state.conversation.id,
          currentUserId: currentUserId,
        );
      }
      if (!mounted) return;
      state = state.copyWith(
        messages: mergeMessages(
          msgs,
          state.messages,
          currentUserId: state.conversation.type == 'guest'
              ? null
              : currentUserId,
        ),
        isLoading: false,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Kh?ng th? t?i tin nh?n.',
        );
      }
    }
  }

  void _setupSignalR() {
    final signalR = _repository.signalR;
    if (signalR == null) return;

    _reconnectSubscription = signalR.onReconnected.listen((_) => load());
    final convId = state.conversation.id;
    if (state.conversation.type != 'guest') {
      signalR.connect(currentUserId: currentUserId).then((_) {
        signalR.joinConversation(convId);
      });
    } else {
      signalR.connect();
    }

    _messageSubscription?.cancel();
    _messageSubscription = signalR.onReceiveMessage.listen((incoming) {
      if (!mounted) return;
      final matchesConv =
          incoming.conversationId == convId ||
          (state.conversation.type == 'guest' &&
              incoming.conversationId ==
                  (state.conversation.guestId ?? convId));
      if (!matchesConv) return;

      final existing = state.messages.any((m) => m.id == incoming.id);
      if (existing) return;

      state = state.copyWith(
        messages: mergeMessages(
          state.messages,
          [incoming],
          currentUserId: state.conversation.type == 'guest'
              ? null
              : currentUserId,
        ),
      );
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return;
    state = state.copyWith(isSending: true);
    try {
      final ChatMessage newMsg;
      if (state.conversation.type == 'guest') {
        final gId = state.conversation.guestId ?? state.conversation.id;
        newMsg = await _repository.sendAdminGuestMessage(gId, text.trim());
      } else {
        newMsg = await _repository.sendMessage(
          conversationId: state.conversation.id,
          content: text.trim(),
          clientMessageId: newClientMessageId(),
          currentUserId: currentUserId,
        );
      }
      if (!mounted) return;
      state = state.copyWith(
        messages: mergeMessages(
          state.messages,
          [newMsg],
          currentUserId: state.conversation.type == 'guest'
              ? null
              : currentUserId,
        ),
        isSending: false,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSending: false,
          error: 'Kh?ng th? g?i tin nh?n.',
        );
      }
    }
  }
}
