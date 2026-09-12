import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:e_learning_mobile/core/network/cache_service.dart';
import 'package:e_learning_mobile/features/notifications/data/models/notification_item.dart';
import 'package:e_learning_mobile/features/notifications/data/notifications_api.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  Future<void> registerDeviceToken({
    required String deviceToken,
    required String deviceType,
    required String deviceId,
    String? appVersion,
  }) async {
    try {
      await _api.registerDeviceToken(
        deviceToken: deviceToken,
        deviceType: deviceType,
        deviceId: deviceId,
        appVersion: appVersion,
      );
    } catch (_) {}
  }

  Future<void> unregisterDeviceToken(String deviceId) async {
    try {
      await _api.unregisterDeviceToken(deviceId);
    } catch (_) {}
  }

  Future<void> syncCurrentDeviceToken() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown_device';
      final platform = Platform.operatingSystem;
      String? version;

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        version = packageInfo.version;
      } catch (_) {}

      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
        }
      } catch (_) {}

      await registerDeviceToken(
        deviceToken: token,
        deviceType: platform,
        deviceId: deviceId,
        appVersion: version,
      );

      debugPrint('====================================');
      debugPrint('✅ FCM TOKEN REGISTERED TO SERVER DB:');
      debugPrint('   Device ID: $deviceId');
      debugPrint('   Platform: $platform');
      debugPrint('   Token: $token');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('⚠️ Failed to sync FCM Device Token: $e');
    }
  }

  Future<void> unregisterCurrentDeviceToken() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown_device';

      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
        }
      } catch (_) {}

      await unregisterDeviceToken(deviceId);

      debugPrint('====================================');
      debugPrint('🗑️ FCM TOKEN UNREGISTERED FROM SERVER DB:');
      debugPrint('   Device ID: $deviceId');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('⚠️ Failed to unregister FCM Device Token: $e');
    }
  }
}
