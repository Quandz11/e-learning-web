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
    this.energyEarned,
    this.badgesEarned = const [],
    this.linkedGoalId,
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
  final int? energyEarned;
  final List<String> badgesEarned;
  final String? linkedGoalId;
  final DateTime createdAt;

  int get effectiveEnergy => energyEarned ?? distanceKm.floor();

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
    final dist = (json['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final rawBadges = json['badgesEarned'];
    List<String> parsedBadges = [];
    if (rawBadges is List) {
      parsedBadges = rawBadges.map((e) => e.toString()).toList();
    } else if (dist >= 3.0) {
      if (dist >= 3.0) parsedBadges.add('badge_flower_bronze_3k');
      if (dist >= 5.0) parsedBadges.add('badge_flower_blue_5k');
      if (dist >= 10.0) parsedBadges.add('badge_flower_red_10k');
      if (dist >= 21.0) parsedBadges.add('badge_flower_purple_21k');
      if (dist >= 42.0) parsedBadges.add('badge_crown_gold_42k');
    }

    return RunningActivity(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      distanceKm: dist,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      paceMinPerKm: (json['paceMinPerKm'] as num?)?.toDouble(),
      paceFormatted: json['paceFormatted']?.toString() ?? '--',
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
      activityDate: DateTime.tryParse(json['activityDate']?.toString() ?? '') ?? DateTime.now(),
      title: json['title']?.toString() ?? 'Chạy bộ',
      notes: json['notes']?.toString(),
      trackingMode: json['trackingMode']?.toString() ?? 'GPS',
      energyEarned: (json['energyEarned'] as num?)?.toInt() ?? dist.floor(),
      badgesEarned: parsedBadges,
      linkedGoalId: json['linkedGoalId']?.toString(),
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
    'energyEarned': effectiveEnergy,
    'badgesEarned': badgesEarned,
    'linkedGoalId': linkedGoalId,
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
    this.totalEnergyEarned,
    this.unlockedBadges = const [],
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
  final int? totalEnergyEarned;
  final List<String> unlockedBadges;

  int get effectiveTotalEnergy => totalEnergyEarned ?? totalDistanceKm.floor();

  String get totalDurationFormatted {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes phút';
  }

  factory RunningSummary.fromJson(Map<String, dynamic> json) {
    final totalDist = (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
    final rawBadges = json['unlockedBadges'];
    List<String> parsedBadges = [];
    if (rawBadges is List) {
      parsedBadges = rawBadges.map((e) => e.toString()).toList();
    }

    return RunningSummary(
      totalDistanceKm: totalDist,
      totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toInt() ?? 0,
      totalRunsCount: (json['totalRunsCount'] as num?)?.toInt() ?? 0,
      weekDistanceKm: (json['weekDistanceKm'] as num?)?.toDouble() ?? 0.0,
      monthDistanceKm: (json['monthDistanceKm'] as num?)?.toDouble() ?? 0.0,
      averagePaceMinPerKm: (json['averagePaceMinPerKm'] as num?)?.toDouble(),
      averagePaceFormatted: json['averagePaceFormatted']?.toString() ?? '--',
      longestRunKm: (json['longestRunKm'] as num?)?.toDouble() ?? 0.0,
      currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
      totalEnergyEarned: (json['totalEnergyEarned'] as num?)?.toInt() ?? totalDist.floor(),
      unlockedBadges: parsedBadges,
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
    this.energyEarned,
    this.linkedGoalId,
  });

  final double distanceKm;
  final int durationSeconds;
  final DateTime? activityDate;
  final String? title;
  final String? notes;
  final String trackingMode;
  final int? energyEarned;
  final String? linkedGoalId;

  Map<String, dynamic> toJson() => {
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    if (activityDate != null) 'activityDate': activityDate!.toIso8601String(),
    if (title != null && title!.isNotEmpty) 'title': title,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'trackingMode': trackingMode,
    if (energyEarned != null) 'energyEarned': energyEarned,
    if (linkedGoalId != null) 'linkedGoalId': linkedGoalId,
  };
}

class RunningBadge {
  const RunningBadge({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.count = 0,
    this.isUnlocked = false,
  });

  final String id;
  final String title;
  final String category; // 'milestone' | 'streak' | 'energy' | 'badge'
  final String description;
  final int count;
  final bool isUnlocked;

  RunningBadge copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    int? count,
    bool? isUnlocked,
  }) {
    return RunningBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      count: count ?? this.count,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

class RunningGoal {
  const RunningGoal({
    required this.id,
    required this.title,
    required this.activitiesCount,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final int activitiesCount;
  final bool isSelected;

  RunningGoal copyWith({
    String? id,
    String? title,
    int? activitiesCount,
    bool? isSelected,
  }) {
    return RunningGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      activitiesCount: activitiesCount ?? this.activitiesCount,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class RunningBadgeCatalog {
  static const milestone3k = RunningBadge(
    id: 'badge_flower_bronze_3k',
    title: 'Hoa vàng',
    category: 'milestone',
    description: 'Đạt mốc 3 KM',
  );
  static const milestone5k = RunningBadge(
    id: 'badge_flower_blue_5k',
    title: 'Hoa xanh',
    category: 'milestone',
    description: 'Đạt mốc 5 KM',
  );
  static const milestone10k = RunningBadge(
    id: 'badge_flower_red_10k',
    title: 'Hoa đỏ',
    category: 'milestone',
    description: 'Đạt mốc 10 KM',
  );
  static const milestone21k = RunningBadge(
    id: 'badge_flower_purple_21k',
    title: 'Hoa tím',
    category: 'milestone',
    description: 'Đạt mốc 21 KM (Bán Marathon)',
  );
  static const milestone42k = RunningBadge(
    id: 'badge_crown_gold_42k',
    title: 'Hoa đặc biệt',
    category: 'milestone',
    description: 'Đạt mốc 42 KM (Marathon)',
  );

  static const streak7 = RunningBadge(
    id: 'badge_streak_7',
    title: '7 ngày',
    category: 'streak',
    description: 'Chuỗi kiên trì 7 ngày',
  );
  static const streak14 = RunningBadge(
    id: 'badge_streak_14',
    title: '14 ngày',
    category: 'streak',
    description: 'Chuỗi kiên trì 14 ngày',
  );
  static const streak28 = RunningBadge(
    id: 'badge_streak_28',
    title: '28 ngày',
    category: 'streak',
    description: 'Chuỗi kiên trì 28 ngày',
  );

  static const energyHeart = RunningBadge(
    id: 'badge_heart_energy',
    title: 'Trái tim',
    category: 'energy',
    description: 'Tích lũy năng lượng chạy bộ',
  );
  static const badgeSilver = RunningBadge(
    id: 'badge_silver',
    title: 'Huy hiệu bạc',
    category: 'badge',
    description: 'Hoàn thành tích cực các buổi chạy',
  );
  static const badgeGold = RunningBadge(
    id: 'badge_gold',
    title: 'Huy hiệu vàng',
    category: 'badge',
    description: 'Chinh phục mục tiêu xuất sắc',
  );

  static List<RunningBadge> getAllBadges({
    Set<String> unlockedIds = const {},
    Map<String, int> counts = const {},
  }) {
    final list = [
      energyHeart,
      milestone3k,
      milestone5k,
      milestone10k,
      milestone21k,
      milestone42k,
      streak7,
      streak14,
      streak28,
      badgeSilver,
      badgeGold,
    ];
    return list.map((b) {
      final isUnlocked = unlockedIds.contains(b.id);
      final count = counts[b.id] ?? (isUnlocked ? 1 : 0);
      return b.copyWith(isUnlocked: isUnlocked, count: count);
    }).toList();
  }
}
