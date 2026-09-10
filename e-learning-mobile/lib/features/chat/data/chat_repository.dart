import 'package:e_learning_mobile/features/chat/data/chat_api.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(chatApiProvider));
});

class ChatRepository {
  const ChatRepository(this._api);

  final ChatApi _api;

  Future<ChatConversation> getOrCreateSupportConversation({String? currentUserId}) async {
    // 1. Get existing conversations
    try {
      final conversations = await _api.getConversations(currentUserId: currentUserId);
      if (conversations.isNotEmpty) {
        return conversations.first;
      }
    } catch (_) {}

    // 2. If no conversation, get default support user
    final supportUser = await _api.getSupportUser();
    if (supportUser != null) {
      return _api.createConversation(supportUser.id, currentUserId: currentUserId);
    }

    throw Exception('Không tìm thấy tư vấn viên hỗ trợ lúc này.');
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {String? currentUserId}) async {
    return _api.getMessages(conversationId, currentUserId: currentUserId);
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    String? currentUserId,
  }) async {
    return _api.sendMessage(
      conversationId: conversationId,
      content: content,
      currentUserId: currentUserId,
    );
  }

  Future<void> markAsRead(String conversationId) async {
    await _api.markAsRead(conversationId);
  }
}
