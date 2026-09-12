import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('🔥 FCM Background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'skvi_wellness_channel';
  static const String channelName = 'Nhắc nhở & Thông báo SKVI';
  static const String channelDesc =
      'Thông báo nhắc nhở uống nước, nhịn ăn, vận động và tin tức hệ thống';

  static const String chatChannelId = 'skvi_chat_channel';
  static const String chatChannelName = 'Tin nhắn trò chuyện';
  static const String chatChannelDesc =
      'Thông báo tin nhắn mới từ hỗ trợ viên và bạn học';

  static const String fallbackChannelId = 'skvi_notifications';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization error: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          chatChannelId,
          chatChannelName,
          description: chatChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          fallbackChannelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }

    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final androidGranted =
        await androidImplementation?.requestNotificationsPermission() ?? true;

    final darwinImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final iosGranted =
        await darwinImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted;
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isChat = false,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      isChat ? chatChannelId : channelId,
      isChat ? chatChannelName : channelName,
      channelDescription: isChat ? chatChannelDesc : channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      category: isChat ? AndroidNotificationCategory.message : null,
      styleInformation: isChat
          ? BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Tin nhắn mới',
            )
          : null,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Failed to show immediate notification: $e');
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to zone schedule notification: $e');
    }
  }

  Future<void> sendTestNotification() async {
    await showImmediateNotification(
      id: 9999,
      title: '🌿 Nhắc nhở Sống khỏe SKVI',
      body: 'Đến giờ uống một cốc nước ấm và vận động nhẹ rồi bạn nhé!',
      payload: 'wellness_reminder',
    );
  }

  Future<void> setupFirebaseMessaging({
    Function(String token)? onTokenRefresh,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        return;
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('====================================');
          debugPrint('🔥 FCM REGISTRATION TOKEN:');
          debugPrint(token);
          debugPrint('====================================');
          if (onTokenRefresh != null) {
            onTokenRefresh(token);
          }
        }

        messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔥 FCM TOKEN REFRESHED: $newToken');
          if (onTokenRefresh != null) {
            onTokenRefresh(newToken);
          }
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          final isChat = message.data['type'] == 'chat';
          if (notification != null) {
            showImmediateNotification(
              id: message.hashCode,
              title: notification.title ?? (isChat ? 'Tin nhắn mới' : 'Thông báo mới'),
              body: notification.body ?? '',
              payload: message.data.toString(),
              isChat: isChat,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Firebase Messaging setup skipped / not configured: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
