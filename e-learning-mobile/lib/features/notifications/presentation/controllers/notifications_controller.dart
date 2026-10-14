import 'dart:async';
import 'package:e_learning_mobile/features/notifications/data/models/notification_item.dart';
import 'package:e_learning_mobile/features/notifications/data/notifications_repository.dart';
import 'package:e_learning_mobile/features/notifications/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsControllerProvider =
    StateNotifierProvider<
      NotificationsController,
      AsyncValue<NotificationsPayload>
    >(
      (ref) =>
          NotificationsController(ref.watch(notificationsRepositoryProvider)),
    );

class NotificationsController
    extends StateNotifier<AsyncValue<NotificationsPayload>> {
  NotificationsController(this._repository)
    : super(const AsyncValue.loading()) {
    load();
    _subscription = NotificationService.instance.onMessageStream.listen(
      _handleIncomingFcm,
    );
  }

  final NotificationsRepository _repository;
  StreamSubscription<RemoteMessage>? _subscription;

  void _handleIncomingFcm(RemoteMessage message) {
    final isChat = message.data['type'] == 'chat';
    if (isChat) return;

    final id =
        message.data['notificationId']?.toString() ??
        message.messageId ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Thông báo mới';
    final content =
        message.notification?.body ?? message.data['body']?.toString();

    final newItem = NotificationItem(
      id: id,
      title: title,
      content: content,
      isRead: false,
      createdAt: DateTime.now(),
    );

    addRealtimeNotification(newItem);

    _repository
        .getNotifications(forceRefresh: true)
        .then((payload) {
          state = AsyncValue.data(payload);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final payload = await _repository.getNotifications(
        forceRefresh: forceRefresh,
      );
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
      final updatedList = current.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
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
    } else {
      state = AsyncValue.data(
        NotificationsPayload(notifications: [item], unreadCount: 1),
      );
    }
  }
}
