import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/notifications/data/models/notification_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(apiClientProvider));
});

class NotificationsApi {
  const NotificationsApi(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationsPayload> getMyNotifications() async {
    final res = await _apiClient.get<Map<String, dynamic>>('/notifications');
    return NotificationsPayload.fromJson(res);
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.put<dynamic>('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.put<dynamic>('/notifications/read-all');
  }

  Future<void> registerDeviceToken({
    required String deviceToken,
    required String deviceType,
    required String deviceId,
  }) async {
    await _apiClient.post<dynamic>(
      '/notifications/device-tokens',
      data: {
        'deviceToken': deviceToken,
        'deviceType': deviceType,
        'deviceId': deviceId,
      },
    );
  }

  Future<void> unregisterDeviceToken(String deviceId) async {
    await _apiClient.delete<dynamic>('/notifications/device-tokens/$deviceId');
  }
}
