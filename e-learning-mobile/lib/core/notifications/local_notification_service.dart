import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint(
            '🔔 [LocalNotificationService] Notification tapped: ${details.payload}',
          );
        },
      );

      // Create Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        'wellness_reminders_channel',
        'Nhắc nhở Sức khỏe & Học tập',
        description:
            'Thông báo hẹn giờ uống nước, nhịn ăn và duy trì chuỗi học tập',
        importance: Importance.high,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ [LocalNotificationService] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [LocalNotificationService] Initialization error: $e');
      }
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'wellness_reminders_channel',
      'Nhắc nhở Sức khỏe & Học tập',
      channelDescription:
          'Thông báo hẹn giờ uống nước, nhịn ăn và duy trì chuỗi học tập',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(id, title, body, details, payload: payload);
      debugPrint(
        '🔔 [LocalNotificationService] Displayed immediate notification #$id',
      );
    } catch (e) {
      debugPrint(
        '⚠️ [LocalNotificationService] Failed to show notification: $e',
      );
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'wellness_reminders_channel',
      'Nhắc nhở Sức khỏe & Học tập',
      channelDescription:
          'Thông báo hẹn giờ uống nước, nhịn ăn và duy trì chuỗi học tập',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint(
        '⏰ [LocalNotificationService] Scheduled daily notification #$id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint(
        '⚠️ [LocalNotificationService] Failed to schedule notification: $e',
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint('🗑️ [LocalNotificationService] Cancelled notification #$id');
    } catch (e) {
      debugPrint('⚠️ [LocalNotificationService] Cancel error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      debugPrint('🗑️ [LocalNotificationService] Cancelled all notifications');
    } catch (e) {
      debugPrint('⚠️ [LocalNotificationService] Cancel all error: $e');
    }
  }
}
