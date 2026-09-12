import 'dart:async';
import 'package:e_learning_mobile/features/chat/data/chat_repository.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
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
    .autoDispose<AdminChatDetailController, AdminChatDetailState, AdminConversationItem>(
  (ref, conversation) {
    final currentUserId = ref.watch(profileControllerProvider).profile?.id;
    return AdminChatDetailController(
      ref.watch(chatRepositoryProvider),
      conversation: conversation,
      currentUserId: currentUserId,
    );
  },
);

class AdminChatDetailController extends StateNotifier<AdminChatDetailState> {
  AdminChatDetailController(
    this._repository, {
    required AdminConversationItem conversation,
    this.currentUserId,
  }) : super(AdminChatDetailState(conversation: conversation, isLoading: true)) {
    load();
    _startPolling();
  }

  final ChatRepository _repository;
  final String? currentUserId;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
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
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
          currentUserId: currentUserId,
        );
      }
      state = state.copyWith(
        messages: [...state.messages, newMsg],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!state.isLoading && !state.isSending) {
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
          if (msgs.length != state.messages.length) {
            state = state.copyWith(messages: msgs);
          }
        } catch (_) {}
      }
    });
  }
}
