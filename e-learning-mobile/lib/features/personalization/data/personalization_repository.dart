import 'dart:convert';
import 'package:e_learning_mobile/features/notifications/services/notification_service.dart';
import 'package:e_learning_mobile/features/personalization/domain/reminder_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationRepository {
  static const _remindersKey = 'personalization_reminders_v1';
  static const _profileKey = 'personalization_profile_v1';

  static final List<Reminder> defaultReminders = [
    const Reminder(
      id: 'rem_water',
      type: ReminderType.water,
      title: 'Uống 250ml nước',
      message: 'Đã đến lúc tiếp nước cho cơ thể rồi!',
      enabled: true,
      intervalMinutes: 60,
      startTimeHour: 7,
      endTimeHour: 21,
    ),
    const Reminder(
      id: 'rem_movement',
      type: ReminderType.movement,
      title: 'Đi lại & vươn vai',
      message: 'Đứng dậy đi lại 5 phút để máu huyết lưu thông.',
      enabled: true,
      intervalMinutes: 120,
      startTimeHour: 9,
      endTimeHour: 18,
    ),
    const Reminder(
      id: 'rem_rest',
      type: ReminderType.rest,
      title: 'Nghỉ ngơi mắt & thư giãn',
      message: 'Nhắm mắt 2 phút, hít thở sâu để tái tạo năng lượng.',
      enabled: true,
      startTimeHour: 12,
      startTimeMinute: 30,
      endTimeHour: 13,
      endTimeMinute: 0,
    ),
    const Reminder(
      id: 'rem_study',
      type: ReminderType.study,
      title: 'Khung giờ học bài',
      message: 'Dành 20 phút học bài hôm nay nhé!',
      enabled: true,
      startTimeHour: 20,
      startTimeMinute: 0,
      endTimeHour: 20,
      endTimeMinute: 30,
    ),
  ];

  Future<PersonalizationProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_profileKey);
    final reminders = await getReminders();

    if (rawProfile != null) {
      try {
        final map = jsonDecode(rawProfile) as Map<String, dynamic>;
        return PersonalizationProfile(
          dailyWaterGoalMl: map['dailyWaterGoalMl'] as int? ?? 2000,
          movementGoalMinutes: map['movementGoalMinutes'] as int? ?? 30,
          studyGoalMinutes: map['studyGoalMinutes'] as int? ?? 45,
          preferredLearningTime:
              map['preferredLearningTime'] as String? ??
              'Buổi tối (19:00 - 21:00)',
          interests:
              (map['interests'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [
                'Nhìn ăn khoa học',
                'Thanh lọc cơ thể',
                'Dinh dưỡng tự nhiên',
              ],
          reminders: reminders,
        );
      } catch (_) {}
    }

    return PersonalizationProfile(reminders: reminders);
  }

  Future<void> saveProfile(PersonalizationProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'dailyWaterGoalMl': profile.dailyWaterGoalMl,
      'movementGoalMinutes': profile.movementGoalMinutes,
      'studyGoalMinutes': profile.studyGoalMinutes,
      'preferredLearningTime': profile.preferredLearningTime,
      'interests': profile.interests,
    };
    await prefs.setString(_profileKey, jsonEncode(map));
  }

  Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remindersKey);
    if (raw == null) {
      await saveReminders(defaultReminders);
      return defaultReminders;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return defaultReminders;
    }
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, encoded);

    // Sync notification schedules
    for (var i = 0; i < reminders.length; i++) {
      final rem = reminders[i];
      final notifId = rem.id.hashCode.abs() % 100000;
      if (rem.enabled) {
        await NotificationService.instance.scheduleDailyNotification(
          id: notifId,
          title: rem.title,
          body: rem.message,
          hour: rem.startTimeHour,
          minute: rem.startTimeMinute,
        );
      } else {
        await NotificationService.instance.cancelNotification(notifId);
      }
    }
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index] = reminders[index].copyWith(enabled: enabled);
      await saveReminders(reminders);
    }
  }

  Future<void> upsertReminder(Reminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
    } else {
      reminders.add(reminder);
    }
    await saveReminders(reminders);
  }

  Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == id);
    await saveReminders(reminders);
    final notifId = id.hashCode.abs() % 100000;
    await NotificationService.instance.cancelNotification(notifId);
  }
}

final personalizationRepositoryProvider = Provider<PersonalizationRepository>(
  (ref) => PersonalizationRepository(),
);

final personalizationStateProvider =
    StateNotifierProvider<
      PersonalizationController,
      AsyncValue<PersonalizationProfile>
    >((ref) {
      final repo = ref.watch(personalizationRepositoryProvider);
      return PersonalizationController(repo);
    });

class PersonalizationController
    extends StateNotifier<AsyncValue<PersonalizationProfile>> {
  PersonalizationController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final PersonalizationRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repo.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    final current = state.value;
    if (current == null) return;
    await _repo.toggleReminder(id, enabled);
    final updatedList = current.reminders.map((r) {
      if (r.id == id) return r.copyWith(enabled: enabled);
      return r;
    }).toList();
    state = AsyncValue.data(current.copyWith(reminders: updatedList));
  }

  Future<void> saveReminder(Reminder reminder) async {
    await _repo.upsertReminder(reminder);
    await load();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    await load();
  }

  Future<void> updateGoals({
    int? waterGoal,
    int? movementGoal,
    int? studyGoal,
  }) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(
      dailyWaterGoalMl: waterGoal ?? current.dailyWaterGoalMl,
      movementGoalMinutes: movementGoal ?? current.movementGoalMinutes,
      studyGoalMinutes: studyGoal ?? current.studyGoalMinutes,
    );
    await _repo.saveProfile(updated);
    state = AsyncValue.data(updated);
  }
}
