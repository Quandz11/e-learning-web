import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_learning_mobile/features/notifications/services/notification_service.dart';

/// Service quản lý và đồng bộ dữ liệu ứng dụng E-Learning SKVI
/// sang hệ thống Widget native (Android AppWidget / iOS WidgetKit SharedPreferences).
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String appGroupId = 'group.vn.nhinanchualanh.elearning';
  static const String androidWidgetProvider = 'LearningWidgetProvider';
  static const String iOSWidgetName = 'SKVIWidget';

  static const String keyWidgetSyncEnabled = 'widget_sync_enabled';
  static const String keySelectedWidgetId = 'widget_selected_id';

  static const String keyStreakDays = 'widget_streak_days';
  static const String keyTargetMinutes = 'widget_target_minutes';
  static const String keyLearnedMinutes = 'widget_learned_minutes';
  static const String keyActiveCourseTitle = 'widget_active_course_title';
  static const String keyActiveCourseProgress = 'widget_active_course_progress';
  static const String keyNextLessonTitle = 'widget_next_lesson_title';
  static const String keyNextReminderTime = 'widget_next_reminder_time';
  static const String keyLastUpdated = 'widget_last_updated';

  /// Khởi tạo App Group ID cho iOS
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('⚠️ [HomeWidgetService] Could not set App Group ID: $e');
    }
  }

  /// Kiểm tra trạng thái bật/tắt đồng bộ Widget
  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyWidgetSyncEnabled) ?? true;
  }

  /// Lưu trạng thái bật/tắt đồng bộ Widget
  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyWidgetSyncEnabled, enabled);
    if (enabled) {
      final currentData = await getWidgetData();
      await updateWidgetData(
        streakDays: currentData['streakDays'] as int,
        targetMinutes: currentData['targetMinutes'] as int,
        learnedMinutes: currentData['learnedMinutes'] as int,
        activeCourseTitle: currentData['activeCourseTitle'] as String,
        activeCourseProgress: currentData['activeCourseProgress'] as int,
        nextLessonTitle: currentData['nextLessonTitle'] as String,
        nextReminderTime: currentData['nextReminderTime'] as String,
      );
    } else {
      // Hủy thông báo Widget ở Notification Center khi tắt đồng bộ
      try {
        await NotificationService.instance.cancelNotification(8888);
      } catch (_) {}
    }
  }

  /// Đọc ID mẫu Widget đang chọn
  Future<String> getSelectedWidgetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySelectedWidgetId) ?? 'streak_small';
  }

  /// Lưu mẫu Widget được người dùng chọn
  Future<void> setSelectedWidgetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySelectedWidgetId, id);
    final currentData = await getWidgetData();
    await updateWidgetData(
      streakDays: currentData['streakDays'] as int,
      targetMinutes: currentData['targetMinutes'] as int,
      learnedMinutes: currentData['learnedMinutes'] as int,
      activeCourseTitle: currentData['activeCourseTitle'] as String,
      activeCourseProgress: currentData['activeCourseProgress'] as int,
      nextLessonTitle: currentData['nextLessonTitle'] as String,
      nextReminderTime: currentData['nextReminderTime'] as String,
    );
  }

  /// Đồng bộ toàn bộ dữ liệu Widget ra hệ thống Android/iOS
  Future<bool> updateWidgetData({
    required int streakDays,
    required int targetMinutes,
    required int learnedMinutes,
    required String activeCourseTitle,
    required int activeCourseProgress,
    required String nextLessonTitle,
    required String nextReminderTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Lưu SharedPreferences local
      await prefs.setInt(keyStreakDays, streakDays);
      await prefs.setInt(keyTargetMinutes, targetMinutes);
      await prefs.setInt(keyLearnedMinutes, learnedMinutes);
      await prefs.setString(keyActiveCourseTitle, activeCourseTitle);
      await prefs.setInt(keyActiveCourseProgress, activeCourseProgress);
      await prefs.setString(keyNextLessonTitle, nextLessonTitle);
      await prefs.setString(keyNextReminderTime, nextReminderTime);
      await prefs.setString(keyLastUpdated, DateTime.now().toIso8601String());

      // Nếu người dùng TẮT đồng bộ widget, ngưng gửi tín hiệu ra OS
      final enabled = prefs.getBool(keyWidgetSyncEnabled) ?? true;
      if (!enabled) {
        debugPrint(
          '⏸ [HomeWidgetService] Widget sync is currently toggled OFF.',
        );
        return true;
      }

      // 2. Thử đẩy dữ liệu ra Native HomeWidget Store (AppGroup / Android SharedPreferences)
      try {
        await initialize();
        await HomeWidget.saveWidgetData<int>(keyStreakDays, streakDays);
        await HomeWidget.saveWidgetData<int>(keyTargetMinutes, targetMinutes);
        await HomeWidget.saveWidgetData<int>(keyLearnedMinutes, learnedMinutes);
        await HomeWidget.saveWidgetData<String>(
          keyActiveCourseTitle,
          activeCourseTitle,
        );
        await HomeWidget.saveWidgetData<int>(
          keyActiveCourseProgress,
          activeCourseProgress,
        );
        await HomeWidget.saveWidgetData<String>(
          keyNextLessonTitle,
          nextLessonTitle,
        );
        await HomeWidget.saveWidgetData<String>(
          keyNextReminderTime,
          nextReminderTime,
        );

        await HomeWidget.updateWidget(
          androidName: 'LearningWidgetProvider',
          qualifiedAndroidName:
              'vn.nhinanchualanh.e_learning_mobile.LearningWidgetProvider',
          iOSName: iOSWidgetName,
        );
        await HomeWidget.updateWidget(
          androidName: 'MediumCourseWidgetProvider',
          qualifiedAndroidName:
              'vn.nhinanchualanh.e_learning_mobile.MediumCourseWidgetProvider',
          iOSName: iOSWidgetName,
        );
        await HomeWidget.updateWidget(
          androidName: 'LargeDashboardWidgetProvider',
          qualifiedAndroidName:
              'vn.nhinanchualanh.e_learning_mobile.LargeDashboardWidgetProvider',
          iOSName: iOSWidgetName,
        );

        // Đẩy Widget ra Trung tâm thông báo & Màn hình khóa (Notification Center Widget)
        await NotificationService.instance.showOngoingNotificationCenterWidget(
          streakDays: streakDays,
          learnedMinutes: learnedMinutes,
          targetMinutes: targetMinutes,
          activeCourseTitle: activeCourseTitle,
        );
      } catch (e) {
        debugPrint(
          'ℹ️ [HomeWidgetService] Native platform channel unavailable in test/web: $e',
        );
      }

      debugPrint(
        '📱 [HomeWidgetService] Synced widget data successfully: Streak $streakDays, Course "$activeCourseTitle"',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [HomeWidgetService] Error updating widget data: $e');
      return false;
    }
  }

  /// Đồng bộ dữ liệu học tập thực tế từ app/API ra Widget native
  Future<void> syncFromUserData({
    int? streakDays,
    int? targetMinutes,
    int? learnedMinutes,
    String? activeCourseTitle,
    int? activeCourseProgress,
    String? nextLessonTitle,
    String? nextReminderTime,
  }) async {
    final current = await getWidgetData();
    await updateWidgetData(
      streakDays: streakDays ?? (current['streakDays'] as int? ?? 0),
      targetMinutes: targetMinutes ?? (current['targetMinutes'] as int? ?? 30),
      learnedMinutes: learnedMinutes ?? (current['learnedMinutes'] as int? ?? 0),
      activeCourseTitle: activeCourseTitle ??
          (current['activeCourseTitle'] as String? ?? 'Nhịn Ăn Chữa Lành'),
      activeCourseProgress: activeCourseProgress ??
          (current['activeCourseProgress'] as int? ?? 0),
      nextLessonTitle: nextLessonTitle ??
          (current['nextLessonTitle'] as String? ?? 'Bắt đầu học hôm nay'),
      nextReminderTime: nextReminderTime ??
          (current['nextReminderTime'] as String? ?? '20:00'),
    );
  }

  /// Đọc dữ liệu Widget hiện tại từ bộ nhớ
  Future<Map<String, dynamic>> getWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'streakDays': prefs.getInt(keyStreakDays) ?? 0,
      'targetMinutes': prefs.getInt(keyTargetMinutes) ?? 30,
      'learnedMinutes': prefs.getInt(keyLearnedMinutes) ?? 0,
      'activeCourseTitle':
          prefs.getString(keyActiveCourseTitle) ??
          'Nhịn Ăn Chữa Lành',
      'activeCourseProgress': prefs.getInt(keyActiveCourseProgress) ?? 0,
      'nextLessonTitle':
          prefs.getString(keyNextLessonTitle) ??
          'Bắt đầu học hôm nay',
      'nextReminderTime': prefs.getString(keyNextReminderTime) ?? '20:00',
      'lastUpdated':
          prefs.getString(keyLastUpdated) ?? DateTime.now().toIso8601String(),
    };
  }
}
