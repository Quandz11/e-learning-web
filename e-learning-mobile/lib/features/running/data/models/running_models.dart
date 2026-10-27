class RunningActivity {
  const RunningActivity({
    required this.id,
    required this.userId,
    required this.distanceKm,
    required this.durationSeconds,
    this.paceMinPerKm,
    required this.paceFormatted,
    required this.caloriesBurned,
    required this.activityDate,
    required this.title,
    this.notes,
    required this.trackingMode,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final double distanceKm;
  final int durationSeconds;
  final double? paceMinPerKm;
  final String paceFormatted;
  final int caloriesBurned;
  final DateTime activityDate;
  final String title;
  final String? notes;
  final String trackingMode;
  final DateTime createdAt;

  bool get isGps => trackingMode.toUpperCase() == 'GPS';

  String get durationFormatted {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory RunningActivity.fromJson(Map<String, dynamic> json) {
    return RunningActivity(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      paceMinPerKm: (json['paceMinPerKm'] as num?)?.toDouble(),
      paceFormatted: json['paceFormatted']?.toString() ?? '--',
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
      activityDate: DateTime.tryParse(json['activityDate']?.toString() ?? '') ?? DateTime.now(),
      title: json['title']?.toString() ?? 'Chạy bộ',
      notes: json['notes']?.toString(),
      trackingMode: json['trackingMode']?.toString() ?? 'GPS',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'paceMinPerKm': paceMinPerKm,
    'paceFormatted': paceFormatted,
    'caloriesBurned': caloriesBurned,
    'activityDate': activityDate.toIso8601String(),
    'title': title,
    'notes': notes,
    'trackingMode': trackingMode,
    'createdAt': createdAt.toIso8601String(),
  };
}

class RunningSummary {
  const RunningSummary({
    this.totalDistanceKm = 0.0,
    this.totalDurationSeconds = 0,
    this.totalCalories = 0,
    this.totalRunsCount = 0,
    this.weekDistanceKm = 0.0,
    this.monthDistanceKm = 0.0,
    this.averagePaceMinPerKm,
    this.averagePaceFormatted = '--',
    this.longestRunKm = 0.0,
    this.currentStreakDays = 0,
  });

  final double totalDistanceKm;
  final int totalDurationSeconds;
  final int totalCalories;
  final int totalRunsCount;
  final double weekDistanceKm;
  final double monthDistanceKm;
  final double? averagePaceMinPerKm;
  final String averagePaceFormatted;
  final double longestRunKm;
  final int currentStreakDays;

  String get totalDurationFormatted {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes phút';
  }

  factory RunningSummary.fromJson(Map<String, dynamic> json) {
    return RunningSummary(
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toInt() ?? 0,
      totalRunsCount: (json['totalRunsCount'] as num?)?.toInt() ?? 0,
      weekDistanceKm: (json['weekDistanceKm'] as num?)?.toDouble() ?? 0.0,
      monthDistanceKm: (json['monthDistanceKm'] as num?)?.toDouble() ?? 0.0,
      averagePaceMinPerKm: (json['averagePaceMinPerKm'] as num?)?.toDouble(),
      averagePaceFormatted: json['averagePaceFormatted']?.toString() ?? '--',
      longestRunKm: (json['longestRunKm'] as num?)?.toDouble() ?? 0.0,
      currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class CreateRunningActivityDto {
  const CreateRunningActivityDto({
    required this.distanceKm,
    required this.durationSeconds,
    this.activityDate,
    this.title,
    this.notes,
    this.trackingMode = 'GPS',
  });

  final double distanceKm;
  final int durationSeconds;
  final DateTime? activityDate;
  final String? title;
  final String? notes;
  final String trackingMode;

  Map<String, dynamic> toJson() => {
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    if (activityDate != null) 'activityDate': activityDate!.toIso8601String(),
    if (title != null && title!.isNotEmpty) 'title': title,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'trackingMode': trackingMode,
  };
}
