import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(apiClientProvider));
});

class ChatApi {
  const ChatApi(this._apiClient);

  final ApiClient _apiClient;

  Future<SupportUser?> getSupportUser() async {
    try {
      final res = await _apiClient.get<Map<String, dynamic>>(
        '/chat/support-user',
      );
      return SupportUser.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<List<ChatConversation>> getConversations({
    String? currentUserId,
  }) async {
    final res = await _apiClient.get<List<dynamic>>('/chat/conversations');
    return res
        .map(
          (e) => ChatConversation.fromJson(
            e as Map<String, dynamic>,
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  Future<ChatConversation> createConversation(
    String recipientId, {
    String? currentUserId,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/chat/conversations',
      data: {'recipientId': recipientId},
    );
    return ChatConversation.fromJson(res, currentUserId: currentUserId);
  }

  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    String? currentUserId,
  }) async {
    final res = await _apiClient.get<List<dynamic>>(
      '/chat/conversations/$conversationId/messages',
    );
    return res
        .map(
          (e) => ChatMessage.fromJson(
            e as Map<String, dynamic>,
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    String? currentUserId,
    String? clientMessageId,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/chat/messages',
      data: {
        'conversationId': conversationId,
        'content': content,
        if (clientMessageId != null) 'clientMessageId': clientMessageId,
      },
    );
    return ChatMessage.fromJson(res, currentUserId: currentUserId);
  }

  Future<void> markAsRead(String conversationId) async {
    await _apiClient.put<dynamic>('/chat/conversations/$conversationId/read');
  }

  Future<AdminConversationsResponse> getAdminConversations() async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/admin/chat/conversations',
    );
    return AdminConversationsResponse.fromJson(res);
  }

  Future<List<ChatMessage>> getAdminGuestMessages(String guestId) async {
    final res = await _apiClient.get<List<dynamic>>(
      '/admin/chat/guest/$guestId/messages',
    );
    return res
        .map(
          (e) => ChatMessage.fromGuestJson(e as Map<String, dynamic>, guestId),
        )
        .toList();
  }

  Future<ChatMessage> sendAdminGuestMessage(
    String guestId,
    String content,
  ) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/admin/chat/guest/$guestId/send',
      data: {'content': content},
    );
    return ChatMessage.fromGuestJson(res, guestId);
  }
}
