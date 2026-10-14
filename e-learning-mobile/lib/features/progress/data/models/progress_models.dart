class LearningProgressSummary {
  const LearningProgressSummary({
    required this.overallProgressPercent,
    required this.totalMinutesLearned,
    required this.completedLessonsCount,
    required this.totalEnrolledCoursesCount,
    required this.currentStreakDays,
    required this.weeklyStudyStats,
  });

  final double overallProgressPercent;
  final int totalMinutesLearned;
  final int completedLessonsCount;
  final int totalEnrolledCoursesCount;
  final int currentStreakDays;
  final List<DailyStudyTime> weeklyStudyStats;

  factory LearningProgressSummary.fromJson(Map<String, dynamic> json) {
    final weeklyList = (json['weeklyStudyStats'] as List<dynamic>? ?? const [])
        .map((e) => DailyStudyTime.fromJson(e as Map<String, dynamic>))
        .toList();

    return LearningProgressSummary(
      overallProgressPercent:
          (json['overallProgressPercent'] as num?)?.toDouble() ?? 0.0,
      totalMinutesLearned: json['totalMinutesLearned'] as int? ?? 0,
      completedLessonsCount: json['completedLessonsCount'] as int? ?? 0,
      totalEnrolledCoursesCount: json['totalEnrolledCoursesCount'] as int? ?? 0,
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      weeklyStudyStats: weeklyList,
    );
  }
}

class DailyStudyTime {
  const DailyStudyTime({
    required this.dayOfWeek,
    required this.dayIndex,
    required this.minutesLearned,
    required this.goalMinutes,
    required this.isToday,
  });

  final String dayOfWeek;
  final int dayIndex;
  final int minutesLearned;
  final int goalMinutes;
  final bool isToday;

  factory DailyStudyTime.fromJson(Map<String, dynamic> json) {
    return DailyStudyTime(
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      dayIndex: json['dayIndex'] as int? ?? 0,
      minutesLearned: json['minutesLearned'] as int? ?? 0,
      goalMinutes: json['goalMinutes'] as int? ?? 30,
      isToday: json['isToday'] as bool? ?? false,
    );
  }
}
