import 'package:flutter/foundation.dart';

@immutable
class WellnessAccess {
  const WellnessAccess({
    this.isUnlocked = false,
    this.currentPackage,
    this.allowedPackages = const [],
    this.requiredPackages = const [],
    this.ctaPath = '/pricing',
    this.reasonCode = '',
    this.message = '',
  });

  factory WellnessAccess.fromJson(Map<String, dynamic> json) {
    return WellnessAccess(
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      currentPackage: json['currentPackage'] as String?,
      allowedPackages:
          (json['allowedPackages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiredPackages:
          (json['requiredPackages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ctaPath: json['ctaPath'] as String? ?? '/pricing',
      reasonCode: json['reasonCode'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  final bool isUnlocked;
  final String? currentPackage;
  final List<String> allowedPackages;
  final List<String> requiredPackages;
  final String ctaPath;
  final String reasonCode;
  final String message;
}

@immutable
class WellnessCheckoutPackage {
  const WellnessCheckoutPackage({
    this.code = '',
    this.name = '',
    this.description = '',
    this.priceVnd = 0,
    this.durationDays = 0,
    this.isFeatured = false,
    this.sortOrder = 0,
  });

  factory WellnessCheckoutPackage.fromJson(Map<String, dynamic> json) {
    return WellnessCheckoutPackage(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceVnd: (json['priceVnd'] as num?)?.toDouble() ?? 0,
      durationDays: json['durationDays'] as int? ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  final String code;
  final String name;
  final String description;
  final double priceVnd;
  final int durationDays;
  final bool isFeatured;
  final int sortOrder;
}

@immutable
class WellnessCheckoutConfig {
  const WellnessCheckoutConfig({
    this.packages = const [],
    this.ctaPath = '/pricing',
    this.isPersonalizedRoadmapPaid = false,
  });

  factory WellnessCheckoutConfig.fromJson(Map<String, dynamic> json) {
    return WellnessCheckoutConfig(
      packages:
          (json['packages'] as List<dynamic>?)
              ?.map(
                (e) =>
                    WellnessCheckoutPackage.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      ctaPath: json['ctaPath'] as String? ?? '/pricing',
      isPersonalizedRoadmapPaid:
          json['isPersonalizedRoadmapPaid'] as bool? ?? false,
    );
  }

  final List<WellnessCheckoutPackage> packages;
  final String ctaPath;
  final bool isPersonalizedRoadmapPaid;
}

@immutable
class WellnessPlan {
  const WellnessPlan({
    required this.id,
    required this.packageType,
    required this.startDate,
    required this.endDate,
    required this.fastingHours,
    required this.eatingHours,
    required this.dailyFastStartMinuteOfDay,
    required this.timezone,
    required this.startWeightKg,
    required this.targetWeightKg,
    this.latestWeightKg,
    required this.status,
    required this.totalDays,
    required this.elapsedDays,
    required this.preparationDays,
    required this.fastingDays,
    required this.refeedDays,
    required this.createdAt,
  });

  factory WellnessPlan.fromJson(Map<String, dynamic> json) {
    return WellnessPlan(
      id: json['id'] as String? ?? '',
      packageType: json['packageType'] as String? ?? 'TRIAL_3_DAYS',
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now(),
      fastingHours: json['fastingHours'] as int? ?? 16,
      eatingHours: json['eatingHours'] as int? ?? 8,
      dailyFastStartMinuteOfDay:
          json['dailyFastStartMinuteOfDay'] as int? ?? 1200,
      timezone: json['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      startWeightKg: (json['startWeightKg'] as num?)?.toDouble() ?? 60.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 55.0,
      latestWeightKg: (json['latestWeightKg'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'ACTIVE',
      totalDays: json['totalDays'] as int? ?? 30,
      elapsedDays: json['elapsedDays'] as int? ?? 0,
      preparationDays: json['preparationDays'] as int? ?? 3,
      fastingDays: json['fastingDays'] as int? ?? 21,
      refeedDays: json['refeedDays'] as int? ?? 6,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String packageType;
  final DateTime startDate;
  final DateTime endDate;
  final int fastingHours;
  final int eatingHours;
  final int dailyFastStartMinuteOfDay;
  final String timezone;
  final double startWeightKg;
  final double targetWeightKg;
  final double? latestWeightKg;
  final String status;
  final int totalDays;
  final int elapsedDays;
  final int preparationDays;
  final int fastingDays;
  final int refeedDays;
  final DateTime createdAt;
}

@immutable
class WellnessDailyLog {
  const WellnessDailyLog({
    this.id,
    required this.logDate,
    this.ateAtLocal,
    this.waterMl = 0,
    this.workoutMinutes = 0,
    this.workoutType = '',
    this.currentWeightKg,
    this.notes = '',
  });

  factory WellnessDailyLog.fromJson(Map<String, dynamic> json) {
    return WellnessDailyLog(
      id: json['id'] as String?,
      logDate:
          DateTime.tryParse(json['logDate']?.toString() ?? '') ??
          DateTime.now(),
      ateAtLocal: DateTime.tryParse(json['ateAtLocal']?.toString() ?? ''),
      waterMl: json['waterMl'] as int? ?? 0,
      workoutMinutes: json['workoutMinutes'] as int? ?? 0,
      workoutType: json['workoutType'] as String? ?? '',
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
    );
  }

  final String? id;
  final DateTime logDate;
  final DateTime? ateAtLocal;
  final int waterMl;
  final int workoutMinutes;
  final String workoutType;
  final double? currentWeightKg;
  final String notes;
}

@immutable
class WellnessFastingStatus {
  const WellnessFastingStatus({
    this.state = 'FASTING',
    required this.windowStartLocal,
    required this.windowEndLocal,
    required this.currentTimeLocal,
    this.progressPercent = 0.0,
    this.remainingMinutes = 0,
    this.label = '',
  });

  factory WellnessFastingStatus.fromJson(Map<String, dynamic> json) {
    return WellnessFastingStatus(
      state: json['state'] as String? ?? 'FASTING',
      windowStartLocal:
          DateTime.tryParse(json['windowStartLocal']?.toString() ?? '') ??
          DateTime.now(),
      windowEndLocal:
          DateTime.tryParse(json['windowEndLocal']?.toString() ?? '') ??
          DateTime.now(),
      currentTimeLocal:
          DateTime.tryParse(json['currentTimeLocal']?.toString() ?? '') ??
          DateTime.now(),
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      remainingMinutes: json['remainingMinutes'] as int? ?? 0,
      label: json['label'] as String? ?? '',
    );
  }

  final String state;
  final DateTime windowStartLocal;
  final DateTime windowEndLocal;
  final DateTime currentTimeLocal;
  final double progressPercent;
  final int remainingMinutes;
  final String label;
}

@immutable
class WellnessResourceItem {
  const WellnessResourceItem({
    this.id = '',
    this.resourceType = '',
    this.title = '',
    this.url = '',
    this.description = '',
  });

  factory WellnessResourceItem.fromJson(Map<String, dynamic> json) {
    return WellnessResourceItem(
      id: json['id'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  final String id;
  final String resourceType;
  final String title;
  final String url;
  final String description;
}

@immutable
class WellnessResourceSet {
  const WellnessResourceSet({
    this.meditation,
    this.breathing,
    this.workout,
    this.selectionStrategy = 'ROTATION',
  });

  factory WellnessResourceSet.fromJson(Map<String, dynamic> json) {
    return WellnessResourceSet(
      meditation: json['meditation'] != null
          ? WellnessResourceItem.fromJson(
              json['meditation'] as Map<String, dynamic>,
            )
          : null,
      breathing: json['breathing'] != null
          ? WellnessResourceItem.fromJson(
              json['breathing'] as Map<String, dynamic>,
            )
          : null,
      workout: json['workout'] != null
          ? WellnessResourceItem.fromJson(
              json['workout'] as Map<String, dynamic>,
            )
          : null,
      selectionStrategy: json['selectionStrategy'] as String? ?? 'ROTATION',
    );
  }

  final WellnessResourceItem? meditation;
  final WellnessResourceItem? breathing;
  final WellnessResourceItem? workout;
  final String selectionStrategy;
}

@immutable
class WellnessInsight {
  const WellnessInsight({
    this.id = '',
    required this.insightDate,
    this.summary = '',
    this.tip = '',
    this.risks = '',
    this.generatedBy = '',
  });

  factory WellnessInsight.fromJson(Map<String, dynamic> json) {
    return WellnessInsight(
      id: json['id'] as String? ?? '',
      insightDate:
          DateTime.tryParse(json['insightDate']?.toString() ?? '') ??
          DateTime.now(),
      summary: json['summary'] as String? ?? '',
      tip: json['tip'] as String? ?? '',
      risks: json['risks'] as String? ?? '',
      generatedBy: json['generatedBy'] as String? ?? '',
    );
  }

  final String id;
  final DateTime insightDate;
  final String summary;
  final String tip;
  final String risks;
  final String generatedBy;
}

@immutable
class WellnessWeightProgress {
  const WellnessWeightProgress({
    this.startWeightKg = 0,
    this.currentWeightKg = 0,
    this.targetWeightKg = 0,
    this.progressPercent = 0,
  });

  factory WellnessWeightProgress.fromJson(Map<String, dynamic> json) {
    return WellnessWeightProgress(
      startWeightKg: (json['startWeightKg'] as num?)?.toDouble() ?? 0,
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  final double startWeightKg;
  final double currentWeightKg;
  final double targetWeightKg;
  final double progressPercent;
}

@immutable
class WellnessUpgradeSuggestion {
  const WellnessUpgradeSuggestion({
    this.level = 'NONE',
    this.title = '',
    this.message = '',
    this.suggestedPackage = '',
    this.ctaPath = '/pricing',
  });

  factory WellnessUpgradeSuggestion.fromJson(Map<String, dynamic> json) {
    return WellnessUpgradeSuggestion(
      level: json['level'] as String? ?? 'NONE',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      suggestedPackage: json['suggestedPackage'] as String? ?? '',
      ctaPath: json['ctaPath'] as String? ?? '/pricing',
    );
  }

  final String level;
  final String title;
  final String message;
  final String suggestedPackage;
  final String ctaPath;
}

@immutable
class WellnessDailyTask {
  const WellnessDailyTask({
    required this.id,
    required this.taskDate,
    required this.lessonId,
    this.courseId,
    this.lessonTitle = '',
    this.description = '',
    this.isCompleted = false,
    this.completedAt,
    this.sortOrder = 0,
  });

  factory WellnessDailyTask.fromJson(Map<String, dynamic> json) {
    return WellnessDailyTask(
      id: json['id'] as String? ?? '',
      taskDate:
          DateTime.tryParse(json['taskDate']?.toString() ?? '') ??
          DateTime.now(),
      lessonId: json['lessonId'] as String? ?? '',
      courseId: json['courseId'] as String?,
      lessonTitle: json['lessonTitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  final String id;
  final DateTime taskDate;
  final String lessonId;
  final String? courseId;
  final String lessonTitle;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;

  WellnessDailyTask copyWith({bool? isCompleted, DateTime? completedAt}) {
    return WellnessDailyTask(
      id: id,
      taskDate: taskDate,
      lessonId: lessonId,
      courseId: courseId,
      lessonTitle: lessonTitle,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder,
    );
  }
}

@immutable
class WellnessDashboard {
  const WellnessDashboard({
    this.plan,
    this.todayLog,
    this.fastingStatus,
    this.todayResources,
    this.todayInsight,
    this.weightProgress,
    this.upgradeSuggestion,
    this.todayTasks = const [],
    this.checkoutConfig = const WellnessCheckoutConfig(),
    this.access = const WellnessAccess(),
  });

  factory WellnessDashboard.fromJson(Map<String, dynamic> json) {
    return WellnessDashboard(
      plan: json['plan'] != null
          ? WellnessPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      todayLog: json['todayLog'] != null
          ? WellnessDailyLog.fromJson(json['todayLog'] as Map<String, dynamic>)
          : null,
      fastingStatus: json['fastingStatus'] != null
          ? WellnessFastingStatus.fromJson(
              json['fastingStatus'] as Map<String, dynamic>,
            )
          : null,
      todayResources: json['todayResources'] != null
          ? WellnessResourceSet.fromJson(
              json['todayResources'] as Map<String, dynamic>,
            )
          : null,
      todayInsight: json['todayInsight'] != null
          ? WellnessInsight.fromJson(
              json['todayInsight'] as Map<String, dynamic>,
            )
          : null,
      weightProgress: json['weightProgress'] != null
          ? WellnessWeightProgress.fromJson(
              json['weightProgress'] as Map<String, dynamic>,
            )
          : null,
      upgradeSuggestion: json['upgradeSuggestion'] != null
          ? WellnessUpgradeSuggestion.fromJson(
              json['upgradeSuggestion'] as Map<String, dynamic>,
            )
          : null,
      todayTasks:
          (json['todayTasks'] as List<dynamic>?)
              ?.map(
                (e) => WellnessDailyTask.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      checkoutConfig: json['checkoutConfig'] != null
          ? WellnessCheckoutConfig.fromJson(
              json['checkoutConfig'] as Map<String, dynamic>,
            )
          : const WellnessCheckoutConfig(),
      access: json['access'] != null
          ? WellnessAccess.fromJson(json['access'] as Map<String, dynamic>)
          : const WellnessAccess(),
    );
  }

  final WellnessPlan? plan;
  final WellnessDailyLog? todayLog;
  final WellnessFastingStatus? fastingStatus;
  final WellnessResourceSet? todayResources;
  final WellnessInsight? todayInsight;
  final WellnessWeightProgress? weightProgress;
  final WellnessUpgradeSuggestion? upgradeSuggestion;
  final List<WellnessDailyTask> todayTasks;
  final WellnessCheckoutConfig checkoutConfig;
  final WellnessAccess access;

  WellnessDashboard copyWith({
    WellnessPlan? plan,
    WellnessDailyLog? todayLog,
    WellnessFastingStatus? fastingStatus,
    WellnessResourceSet? todayResources,
    WellnessInsight? todayInsight,
    WellnessWeightProgress? weightProgress,
    WellnessUpgradeSuggestion? upgradeSuggestion,
    List<WellnessDailyTask>? todayTasks,
    WellnessCheckoutConfig? checkoutConfig,
    WellnessAccess? access,
  }) {
    return WellnessDashboard(
      plan: plan ?? this.plan,
      todayLog: todayLog ?? this.todayLog,
      fastingStatus: fastingStatus ?? this.fastingStatus,
      todayResources: todayResources ?? this.todayResources,
      todayInsight: todayInsight ?? this.todayInsight,
      weightProgress: weightProgress ?? this.weightProgress,
      upgradeSuggestion: upgradeSuggestion ?? this.upgradeSuggestion,
      todayTasks: todayTasks ?? this.todayTasks,
      checkoutConfig: checkoutConfig ?? this.checkoutConfig,
      access: access ?? this.access,
    );
  }
}

@immutable
class WellnessCoachReply {
  const WellnessCoachReply({required this.reply, required this.createdAt});

  factory WellnessCoachReply.fromJson(Map<String, dynamic> json) {
    return WellnessCoachReply(
      reply: json['reply'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String reply;
  final DateTime createdAt;
}

@immutable
class WellnessMealSuggestion {
  const WellnessMealSuggestion({
    required this.ingredients,
    required this.servings,
    required this.menu,
    required this.nutritionNotes,
    required this.createdAt,
  });

  factory WellnessMealSuggestion.fromJson(Map<String, dynamic> json) {
    return WellnessMealSuggestion(
      ingredients: json['ingredients'] as String? ?? '',
      servings: json['servings'] as int? ?? 1,
      menu: json['menu'] as String? ?? '',
      nutritionNotes: json['nutritionNotes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String ingredients;
  final int servings;
  final String menu;
  final String nutritionNotes;
  final DateTime createdAt;
}

@immutable
class WellnessProgressTimelineItem {
  const WellnessProgressTimelineItem({
    required this.logDate,
    this.currentWeightKg,
    this.waterMl = 0,
    this.workoutMinutes = 0,
    this.workoutType = '',
    this.hasCheckin = false,
    this.phase = '',
    this.phaseDayIndex = 0,
    this.phaseTotalDays = 0,
  });

  factory WellnessProgressTimelineItem.fromJson(Map<String, dynamic> json) {
    return WellnessProgressTimelineItem(
      logDate:
          DateTime.tryParse(json['logDate']?.toString() ?? '') ??
          DateTime.now(),
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble(),
      waterMl: json['waterMl'] as int? ?? 0,
      workoutMinutes: json['workoutMinutes'] as int? ?? 0,
      workoutType: json['workoutType'] as String? ?? '',
      hasCheckin: json['hasCheckin'] as bool? ?? false,
      phase: json['phase'] as String? ?? '',
      phaseDayIndex: json['phaseDayIndex'] as int? ?? 0,
      phaseTotalDays: json['phaseTotalDays'] as int? ?? 0,
    );
  }

  final DateTime logDate;
  final double? currentWeightKg;
  final int waterMl;
  final int workoutMinutes;
  final String workoutType;
  final bool hasCheckin;
  final String phase;
  final int phaseDayIndex;
  final int phaseTotalDays;
}

@immutable
class WellnessProgressTimeline {
  const WellnessProgressTimeline({
    required this.fromDate,
    required this.toDate,
    this.requestedDays = 30,
    this.loggedDays = 0,
    this.latestWeightKg,
    this.averageWaterMl = 0,
    this.totalWorkoutMinutes = 0,
    this.items = const [],
  });

  factory WellnessProgressTimeline.fromJson(Map<String, dynamic> json) {
    return WellnessProgressTimeline(
      fromDate:
          DateTime.tryParse(json['fromDate']?.toString() ?? '') ??
          DateTime.now(),
      toDate:
          DateTime.tryParse(json['toDate']?.toString() ?? '') ?? DateTime.now(),
      requestedDays: json['requestedDays'] as int? ?? 30,
      loggedDays: json['loggedDays'] as int? ?? 0,
      latestWeightKg: (json['latestWeightKg'] as num?)?.toDouble(),
      averageWaterMl: json['averageWaterMl'] as int? ?? 0,
      totalWorkoutMinutes: json['totalWorkoutMinutes'] as int? ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => WellnessProgressTimelineItem.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  final DateTime fromDate;
  final DateTime toDate;
  final int requestedDays;
  final int loggedDays;
  final double? latestWeightKg;
  final int averageWaterMl;
  final int totalWorkoutMinutes;
  final List<WellnessProgressTimelineItem> items;
}

// Request Payload Classes

class UpsertWellnessPlanRequest {
  const UpsertWellnessPlanRequest({
    this.packageType = 'TRIAL_3_DAYS',
    required this.startDate,
    this.endDate,
    this.fastingHours = 16,
    this.eatingHours = 8,
    this.dailyFastStartMinuteOfDay = 1200,
    required this.startWeightKg,
    required this.targetWeightKg,
    this.timezone = 'Asia/Ho_Chi_Minh',
  });

  final String packageType;
  final DateTime startDate;
  final DateTime? endDate;
  final int fastingHours;
  final int eatingHours;
  final int dailyFastStartMinuteOfDay;
  final double startWeightKg;
  final double targetWeightKg;
  final String timezone;

  Map<String, dynamic> toJson() => {
    'packageType': packageType,
    'startDate': startDate.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    'fastingHours': fastingHours,
    'eatingHours': eatingHours,
    'dailyFastStartMinuteOfDay': dailyFastStartMinuteOfDay,
    'startWeightKg': startWeightKg,
    'targetWeightKg': targetWeightKg,
    'timezone': timezone,
  };
}

class UpdateWellnessScheduleRequest {
  const UpdateWellnessScheduleRequest({
    required this.startDate,
    required this.endDate,
    this.fastingHours = 16,
    this.eatingHours = 8,
    this.dailyFastStartMinuteOfDay = 1200,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int fastingHours;
  final int eatingHours;
  final int dailyFastStartMinuteOfDay;

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'fastingHours': fastingHours,
    'eatingHours': eatingHours,
    'dailyFastStartMinuteOfDay': dailyFastStartMinuteOfDay,
  };
}

class UpsertWellnessDailyLogRequest {
  const UpsertWellnessDailyLogRequest({
    required this.logDate,
    this.ateAtLocal,
    this.waterMl = 0,
    this.workoutMinutes = 0,
    this.workoutType = '',
    this.currentWeightKg,
    this.notes = '',
  });

  final DateTime logDate;
  final DateTime? ateAtLocal;
  final int waterMl;
  final int workoutMinutes;
  final String workoutType;
  final double? currentWeightKg;
  final String notes;

  Map<String, dynamic> toJson() => {
    'logDate': logDate.toIso8601String(),
    if (ateAtLocal != null) 'ateAtLocal': ateAtLocal!.toIso8601String(),
    'waterMl': waterMl,
    'workoutMinutes': workoutMinutes,
    'workoutType': workoutType,
    if (currentWeightKg != null) 'currentWeightKg': currentWeightKg,
    'notes': notes,
  };
}

class WellnessCoachMoodRequest {
  const WellnessCoachMoodRequest({
    required this.mood,
    required this.energy,
    required this.hunger,
    required this.thirst,
    this.stress = 'Normal',
    this.sleepHours,
    this.notes = '',
  });

  final String mood;
  final String energy;
  final String hunger;
  final String thirst;
  final String stress;
  final int? sleepHours;
  final String notes;

  Map<String, dynamic> toJson() => {
    'mood': mood,
    'energy': energy,
    'hunger': hunger,
    'thirst': thirst,
    'stress': stress,
    if (sleepHours != null) 'sleepHours': sleepHours,
    'notes': notes,
  };
}

class WellnessCoachMealRequest {
  const WellnessCoachMealRequest({
    required this.ingredients,
    this.servings = 1,
    this.goal = 'healthy',
    this.dietaryPreference = '',
  });

  final List<String> ingredients;
  final int servings;
  final String goal;
  final String dietaryPreference;

  Map<String, dynamic> toJson() => {
    'ingredients': ingredients,
    'servings': servings,
    'goal': goal,
    'dietaryPreference': dietaryPreference,
  };
}
