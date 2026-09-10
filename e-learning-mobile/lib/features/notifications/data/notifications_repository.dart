import 'package:e_learning_mobile/core/network/cache_service.dart';
import 'package:e_learning_mobile/features/notifications/data/models/notification_item.dart';
import 'package:e_learning_mobile/features/notifications/data/notifications_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(
    ref.watch(notificationsApiProvider),
    ref.watch(cacheServiceProvider),
  );
});

class NotificationsRepository {
  NotificationsRepository(this._api, this._cacheService);

  final NotificationsApi _api;
  final CacheService _cacheService;
  static const String _cacheKey = 'notifications_inbox';

  Future<NotificationsPayload> getNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cacheService.getMap(_cacheKey);
      if (cached != null) {
        try {
          return NotificationsPayload.fromJson(cached);
        } catch (_) {}
      }
    }

    final payload = await _api.getMyNotifications();
    await _cacheService.set(_cacheKey, {
      'notifications': payload.notifications.map((n) => n.toJson()).toList(),
      'unreadCount': payload.unreadCount,
    });
    return payload;
  }

  Future<void> markAsRead(String id) async {
    await _api.markAsRead(id);
    final cached = await _cacheService.getMap(_cacheKey);
    if (cached != null) {
      try {
        final payload = NotificationsPayload.fromJson(cached);
        final updatedList = payload.notifications.map((n) {
          if (n.id == id) return n.copyWith(isRead: true);
          return n;
        }).toList();
        final unread = updatedList.where((n) => !n.isRead).length;
        await _cacheService.set(_cacheKey, {
          'notifications': updatedList.map((n) => n.toJson()).toList(),
          'unreadCount': unread,
        });
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    await _api.markAllAsRead();
    final cached = await _cacheService.getMap(_cacheKey);
    if (cached != null) {
      try {
        final payload = NotificationsPayload.fromJson(cached);
        final updatedList = payload.notifications.map((n) => n.copyWith(isRead: true)).toList();
        await _cacheService.set(_cacheKey, {
          'notifications': updatedList.map((n) => n.toJson()).toList(),
          'unreadCount': 0,
        });
      } catch (_) {}
    }
  }
}
