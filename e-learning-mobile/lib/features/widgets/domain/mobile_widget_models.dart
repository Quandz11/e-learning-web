class MobileWidgetStateData {
  final int streakDays;
  final int targetMinutes;
  final int learnedMinutes;
  final String activeCourseTitle;
  final int activeCourseProgress;
  final String nextLessonTitle;
  final String nextReminderTime;

  const MobileWidgetStateData({
    required this.streakDays,
    required this.targetMinutes,
    required this.learnedMinutes,
    required this.activeCourseTitle,
    required this.activeCourseProgress,
    required this.nextLessonTitle,
    required this.nextReminderTime,
  });

  factory MobileWidgetStateData.defaultData() {
    return const MobileWidgetStateData(
      streakDays: 7,
      targetMinutes: 30,
      learnedMinutes: 25,
      activeCourseTitle: 'Lập trình Flutter nâng cao',
      activeCourseProgress: 65,
      nextLessonTitle: 'Bài 5: State Management với Riverpod',
      nextReminderTime: '20:00',
    );
  }

  factory MobileWidgetStateData.fromMap(Map<String, dynamic> map) {
    return MobileWidgetStateData(
      streakDays: map['streakDays'] as int? ?? 7,
      targetMinutes: map['targetMinutes'] as int? ?? 30,
      learnedMinutes: map['learnedMinutes'] as int? ?? 25,
      activeCourseTitle: map['activeCourseTitle'] as String? ?? 'Lập trình Flutter nâng cao',
      activeCourseProgress: map['activeCourseProgress'] as int? ?? 65,
      nextLessonTitle: map['nextLessonTitle'] as String? ?? 'Bài 5: State Management với Riverpod',
      nextReminderTime: map['nextReminderTime'] as String? ?? '20:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'streakDays': streakDays,
      'targetMinutes': targetMinutes,
      'learnedMinutes': learnedMinutes,
      'activeCourseTitle': activeCourseTitle,
      'activeCourseProgress': activeCourseProgress,
      'nextLessonTitle': nextLessonTitle,
      'nextReminderTime': nextReminderTime,
    };
  }

  double get goalProgressRatio {
    if (targetMinutes <= 0) return 1.0;
    final ratio = learnedMinutes / targetMinutes;
    return ratio > 1.0 ? 1.0 : ratio;
  }
}
