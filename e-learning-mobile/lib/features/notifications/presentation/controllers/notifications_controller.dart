import 'package:e_learning_mobile/features/notifications/data/models/notification_item.dart';
import 'package:e_learning_mobile/features/notifications/data/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, AsyncValue<NotificationsPayload>>(
  (ref) => NotificationsController(ref.watch(notificationsRepositoryProvider)),
);

class NotificationsController extends StateNotifier<AsyncValue<NotificationsPayload>> {
  NotificationsController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final NotificationsRepository _repository;

  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final payload = await _repository.getNotifications(forceRefresh: forceRefresh);
      state = AsyncValue.data(payload);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    final current = state.value;
    if (current != null) {
      final updatedList = current.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      final unread = updatedList.where((n) => !n.isRead).length;
      state = AsyncValue.data(
        NotificationsPayload(notifications: updatedList, unreadCount: unread),
      );
    }
    try {
      await _repository.markAsRead(id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final current = state.value;
    if (current != null) {
      final updatedList = current.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncValue.data(
        NotificationsPayload(notifications: updatedList, unreadCount: 0),
      );
    }
    try {
      await _repository.markAllAsRead();
    } catch (_) {}
  }

  void addRealtimeNotification(NotificationItem item) {
    final current = state.value;
    if (current != null) {
      final updatedList = [item, ...current.notifications];
      final unread = updatedList.where((n) => !n.isRead).length;
      state = AsyncValue.data(
        NotificationsPayload(notifications: updatedList, unreadCount: unread),
      );
    }
  }
}
