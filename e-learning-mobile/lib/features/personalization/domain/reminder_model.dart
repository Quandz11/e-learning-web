import 'package:flutter/material.dart';

enum ReminderType {
  water,
  movement,
  rest,
  study,
  custom;

  String get displayName {
    switch (this) {
      case ReminderType.water:
        return 'Uống nước';
      case ReminderType.movement:
        return 'Vận động / Đi lại';
      case ReminderType.rest:
        return 'Nghỉ ngơi';
      case ReminderType.study:
        return 'Giờ học tập';
      case ReminderType.custom:
        return 'Nhắc nhở tùy chỉnh';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderType.water:
        return Icons.water_drop_rounded;
      case ReminderType.movement:
        return Icons.directions_walk_rounded;
      case ReminderType.rest:
        return Icons.bedtime_rounded;
      case ReminderType.study:
        return Icons.menu_book_rounded;
      case ReminderType.custom:
        return Icons.notifications_active_rounded;
    }
  }
}

class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.enabled = true,
    this.intervalMinutes,
    this.startTimeHour = 8,
    this.startTimeMinute = 0,
    this.endTimeHour = 21,
    this.endTimeMinute = 0,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  final String id;
  final ReminderType type;
  final String title;
  final String message;
  final bool enabled;
  final int? intervalMinutes;
  final int startTimeHour;
  final int startTimeMinute;
  final int endTimeHour;
  final int endTimeMinute;
  final List<int> repeatDays;
  final bool soundEnabled;
  final bool vibrationEnabled;

  Reminder copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? message,
    bool? enabled,
    int? intervalMinutes,
    int? startTimeHour,
    int? startTimeMinute,
    int? endTimeHour,
    int? endTimeMinute,
    List<int>? repeatDays,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      startTimeHour: startTimeHour ?? this.startTimeHour,
      startTimeMinute: startTimeMinute ?? this.startTimeMinute,
      endTimeHour: endTimeHour ?? this.endTimeHour,
      endTimeMinute: endTimeMinute ?? this.endTimeMinute,
      repeatDays: repeatDays ?? this.repeatDays,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'enabled': enabled,
      'intervalMinutes': intervalMinutes,
      'startTimeHour': startTimeHour,
      'startTimeMinute': startTimeMinute,
      'endTimeHour': endTimeHour,
      'endTimeMinute': endTimeMinute,
      'repeatDays': repeatDays,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.custom,
      ),
      title: json['title'] as String? ?? 'Nhắc nhở',
      message: json['message'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      intervalMinutes: json['intervalMinutes'] as int?,
      startTimeHour: json['startTimeHour'] as int? ?? 8,
      startTimeMinute: json['startTimeMinute'] as int? ?? 0,
      endTimeHour: json['endTimeHour'] as int? ?? 21,
      endTimeMinute: json['endTimeMinute'] as int? ?? 0,
      repeatDays:
          (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
    );
  }
}

class PersonalizationProfile {
  const PersonalizationProfile({
    this.dailyWaterGoalMl = 2000,
    this.movementGoalMinutes = 30,
    this.studyGoalMinutes = 45,
    this.preferredLearningTime = 'Buổi tối (19:00 - 21:00)',
    this.interests = const [
      'Nhìn ăn khoa học',
      'Thanh lọc cơ thể',
      'Dinh dưỡng tự nhiên',
    ],
    this.reminders = const [],
  });

  final int dailyWaterGoalMl;
  final int movementGoalMinutes;
  final int studyGoalMinutes;
  final String preferredLearningTime;
  final List<String> interests;
  final List<Reminder> reminders;

  PersonalizationProfile copyWith({
    int? dailyWaterGoalMl,
    int? movementGoalMinutes,
    int? studyGoalMinutes,
    String? preferredLearningTime,
    List<String>? interests,
    List<Reminder>? reminders,
  }) {
    return PersonalizationProfile(
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      movementGoalMinutes: movementGoalMinutes ?? this.movementGoalMinutes,
      studyGoalMinutes: studyGoalMinutes ?? this.studyGoalMinutes,
      preferredLearningTime:
          preferredLearningTime ?? this.preferredLearningTime,
      interests: interests ?? this.interests,
      reminders: reminders ?? this.reminders,
    );
  }
}
