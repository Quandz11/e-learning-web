import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';

final chatNotificationRepositoryProvider = Provider<ChatNotificationRepository>(
  (ref) {
    return ChatNotificationRepository(ref.read(apiClientProvider));
  },
);

class ChatNotificationRepository {
  ChatNotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getConversations() async {
    final data = await _apiClient.get<List<dynamic>>('/chat/conversations');
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final data = await _apiClient.get<List<dynamic>>(
      '/chat/conversations/$conversationId/messages',
    );
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/chat/messages',
      data: {'conversationId': conversationId, 'content': content},
    );
  }

  Future<void> markConversationRead(String conversationId) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/read',
    );
  }

  Future<int> getUnreadChatCount() async {
    final count = await _apiClient.get<dynamic>('/chat/unread-count');
    if (count is int) {
      return count;
    }
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }

  Future<Map<String, dynamic>> getNotifications() async {
    return _apiClient.get<Map<String, dynamic>>('/notifications');
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/notifications/$notificationId/read',
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _apiClient.put<Map<String, dynamic>>('/notifications/read-all');
  }

  Future<void> registerDeviceToken({
    required String deviceId,
    required String token,
    required String platform,
    String? appVersion,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/notifications/device-tokens',
      data: {
        'deviceId': deviceId,
        'token': token,
        'platform': platform,
        'appVersion': appVersion,
      },
    );
  }

  Future<void> unregisterDeviceToken(String deviceId) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/notifications/device-tokens/${Uri.encodeComponent(deviceId)}',
    );
  }
}
