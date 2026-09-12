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
      final res = await _apiClient.get<Map<String, dynamic>>('/chat/support-user');
      return SupportUser.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<List<ChatConversation>> getConversations({String? currentUserId}) async {
    final res = await _apiClient.get<List<dynamic>>('/chat/conversations');
    return res
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<ChatConversation> createConversation(String recipientId, {String? currentUserId}) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/chat/conversations',
      data: {'recipientId': recipientId},
    );
    return ChatConversation.fromJson(res, currentUserId: currentUserId);
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {String? currentUserId}) async {
    final res = await _apiClient.get<List<dynamic>>('/chat/conversations/$conversationId/messages');
    return res
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    String? currentUserId,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/chat/messages',
      data: {
        'conversationId': conversationId,
        'content': content,
      },
    );
    return ChatMessage.fromJson(res, currentUserId: currentUserId);
  }

  Future<void> markAsRead(String conversationId) async {
    await _apiClient.put<dynamic>('/chat/conversations/$conversationId/read');
  }

  Future<AdminConversationsResponse> getAdminConversations() async {
    final res = await _apiClient.get<Map<String, dynamic>>('/admin/chat/conversations');
    return AdminConversationsResponse.fromJson(res);
  }

  Future<List<ChatMessage>> getAdminGuestMessages(String guestId) async {
    final res = await _apiClient.get<List<dynamic>>('/admin/chat/guest/$guestId/messages');
    return res.map((e) {
      final map = e as Map<String, dynamic>;
      final isFromGuest = map['isFromGuest'] as bool? ?? false;
      return ChatMessage(
        id: map['id']?.toString() ?? '',
        conversationId: guestId,
        senderId: isFromGuest ? guestId : 'admin',
        senderName: map['senderName']?.toString() ?? (isFromGuest ? 'Khách' : 'Ban Cố Vấn'),
        senderRole: isFromGuest ? 'Guest' : 'Admin',
        content: map['content']?.toString() ?? '',
        sentAt: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isRead: map['isRead'] as bool? ?? true,
        isMe: !isFromGuest,
      );
    }).toList();
  }

  Future<ChatMessage> sendAdminGuestMessage(String guestId, String content) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/admin/chat/guest/$guestId/send',
      data: {'content': content},
    );
    final isFromGuest = res['isFromGuest'] as bool? ?? false;
    return ChatMessage(
      id: res['id']?.toString() ?? '',
      conversationId: guestId,
      senderId: isFromGuest ? guestId : 'admin',
      senderName: res['senderName']?.toString() ?? 'Ban Cố Vấn',
      senderRole: 'Admin',
      content: res['content']?.toString() ?? content,
      sentAt: res['timestamp'] != null
          ? DateTime.tryParse(res['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: true,
      isMe: true,
    );
  }
}
