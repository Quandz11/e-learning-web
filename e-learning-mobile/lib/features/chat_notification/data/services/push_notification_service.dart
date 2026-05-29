import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/telemetry/app_logger.dart';
import '../repositories/chat_notification_repository.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(
    repository: ref.read(chatNotificationRepositoryProvider),
    logger: ref.read(appLoggerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushNotificationService {
  PushNotificationService({required this.repository, required this.logger});

  final ChatNotificationRepository repository;
  final AppLogger logger;

  StreamSubscription<String>? _tokenRefreshSub;
  bool _firebaseReady = false;
  bool _registering = false;
  String? _registeredDeviceId;

  Future<void> initializeForSession() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    if (_registering) {
      return;
    }

    _registering = true;
    try {
      final firebaseReady = await _ensureFirebaseReady();
      if (!firebaseReady) {
        return;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await messaging.setAutoInitEnabled(true);

      final token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }

      final deviceId = await _resolveDeviceId();
      final packageInfo = await PackageInfo.fromPlatform();
      await _registerToken(
        deviceId: deviceId,
        token: token,
        appVersion: packageInfo.version,
      );

      _tokenRefreshSub ??= messaging.onTokenRefresh.listen((nextToken) {
        unawaited(
          _registerToken(
            deviceId: deviceId,
            token: nextToken,
            appVersion: packageInfo.version,
          ),
        );
      });
    } catch (error, stackTrace) {
      logger.error('Push notification registration failed', error, stackTrace);
    } finally {
      _registering = false;
    }
  }

  Future<void> clearRegistration() async {
    final deviceId = _registeredDeviceId;
    _registeredDeviceId = null;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    if (deviceId == null || deviceId.isEmpty) {
      return;
    }

    try {
      await repository.unregisterDeviceToken(deviceId);
    } catch (error, stackTrace) {
      logger.error('Push notification unregister failed', error, stackTrace);
    }
  }

  Future<bool> _ensureFirebaseReady() async {
    if (_firebaseReady) {
      return true;
    }

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseReady = true;
      return true;
    } catch (error, stackTrace) {
      logger.warn('Firebase is not configured for this build: $error');
      logger.error('Firebase initialization stack', error, stackTrace);
      return false;
    }
  }

  Future<void> _registerToken({
    required String deviceId,
    required String token,
    required String appVersion,
  }) async {
    await repository.registerDeviceToken(
      deviceId: deviceId,
      token: token,
      platform: Platform.isIOS ? 'IOS' : 'ANDROID',
      appVersion: appVersion,
    );
    _registeredDeviceId = deviceId;
  }

  Future<String> _resolveDeviceId() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await plugin.androidInfo;
      return android.id;
    }

    final ios = await plugin.iosInfo;
    return ios.identifierForVendor ?? 'ios-${ios.name}-${ios.systemVersion}';
  }

  void dispose() {
    unawaited(_tokenRefreshSub?.cancel());
  }
}
