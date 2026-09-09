import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/data/wellness_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WellnessStatus { initial, loading, success, failure }

@immutable
class WellnessState {
  const WellnessState({
    this.status = WellnessStatus.initial,
    this.dashboard,
    this.timeline,
    this.failure,
    this.isSubmittingLog = false,
    this.isCoachLoading = false,
    this.lastCoachReply,
    this.lastMealSuggestion,
    this.actionMessage,
  });

  final WellnessStatus status;
  final WellnessDashboard? dashboard;
  final WellnessProgressTimeline? timeline;
  final AppFailure? failure;
  final bool isSubmittingLog;
  final bool isCoachLoading;
  final WellnessCoachReply? lastCoachReply;
  final WellnessMealSuggestion? lastMealSuggestion;
  final String? actionMessage;

  bool get isLoading => status == WellnessStatus.loading && dashboard == null;

  WellnessState copyWith({
    WellnessStatus? status,
    WellnessDashboard? dashboard,
    WellnessProgressTimeline? timeline,
    AppFailure? failure,
    bool? isSubmittingLog,
    bool? isCoachLoading,
    WellnessCoachReply? lastCoachReply,
    WellnessMealSuggestion? lastMealSuggestion,
    String? actionMessage,
  }) {
    return WellnessState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      timeline: timeline ?? this.timeline,
      failure: failure ?? this.failure,
      isSubmittingLog: isSubmittingLog ?? this.isSubmittingLog,
      isCoachLoading: isCoachLoading ?? this.isCoachLoading,
      lastCoachReply: lastCoachReply ?? this.lastCoachReply,
      lastMealSuggestion: lastMealSuggestion ?? this.lastMealSuggestion,
      actionMessage: actionMessage,
    );
  }
}

final wellnessControllerProvider =
    StateNotifierProvider<WellnessController, WellnessState>((ref) {
  final api = ref.watch(wellnessApiProvider);
  return WellnessController(api);
});

class WellnessController extends StateNotifier<WellnessState> {
  WellnessController(this._api) : super(const WellnessState());

  final WellnessApi _api;

  Future<void> ensureLoaded() async {
    if (state.status == WellnessStatus.initial) {
      await loadDashboard();
    }
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(status: WellnessStatus.loading);
    try {
      final dashboard = await _api.getDashboard();
      state = state.copyWith(
        status: WellnessStatus.success,
        dashboard: dashboard,
        failure: null,
      );
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : AppFailure(
              type: AppFailureType.unknown,
              message: e.toString(),
            );
      state = state.copyWith(
        status: WellnessStatus.failure,
        failure: failure,
      );
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }

  Future<void> logWaterDelta(int deltaMl) async {
    final dash = state.dashboard;
    final plan = dash?.plan;
    if (dash == null || plan == null) return;

    final currentLog = dash.todayLog ??
        WellnessDailyLog(logDate: DateTime.now(), waterMl: 0);
    final newWater = (currentLog.waterMl + deltaMl).clamp(0, 10000);

    // Optimistic update
    final updatedLog = WellnessDailyLog(
      id: currentLog.id,
      logDate: currentLog.logDate,
      ateAtLocal: currentLog.ateAtLocal,
      waterMl: newWater,
      workoutMinutes: currentLog.workoutMinutes,
      workoutType: currentLog.workoutType,
      currentWeightKg: currentLog.currentWeightKg,
      notes: currentLog.notes,
    );
    state = state.copyWith(
      dashboard: dash.copyWith(todayLog: updatedLog),
      isSubmittingLog: true,
    );

    try {
      final serverLog = await _api.upsertDailyLog(
        plan.id,
        UpsertWellnessDailyLogRequest(
          logDate: currentLog.logDate,
          ateAtLocal: currentLog.ateAtLocal,
          waterMl: newWater,
          workoutMinutes: currentLog.workoutMinutes,
          workoutType: currentLog.workoutType,
          currentWeightKg: currentLog.currentWeightKg,
          notes: currentLog.notes,
        ),
      );
      state = state.copyWith(
        dashboard: state.dashboard?.copyWith(todayLog: serverLog),
        isSubmittingLog: false,
      );
    } catch (_) {
      state = state.copyWith(isSubmittingLog: false);
    }
  }

  Future<void> logWorkout(int minutes, String type) async {
    final dash = state.dashboard;
    final plan = dash?.plan;
    if (dash == null || plan == null) return;

    final currentLog = dash.todayLog ?? WellnessDailyLog(logDate: DateTime.now());
    state = state.copyWith(isSubmittingLog: true);

    try {
      final serverLog = await _api.upsertDailyLog(
        plan.id,
        UpsertWellnessDailyLogRequest(
          logDate: currentLog.logDate,
          ateAtLocal: currentLog.ateAtLocal,
          waterMl: currentLog.waterMl,
          workoutMinutes: minutes,
          workoutType: type,
          currentWeightKg: currentLog.currentWeightKg,
          notes: currentLog.notes,
        ),
      );
      state = state.copyWith(
        dashboard: state.dashboard?.copyWith(todayLog: serverLog),
        isSubmittingLog: false,
        actionMessage: 'Đã lưu $minutes phút vận động ($type)',
      );
    } catch (e) {
      state = state.copyWith(isSubmittingLog: false);
    }
  }

  Future<void> logWeight(double weightKg) async {
    final dash = state.dashboard;
    final plan = dash?.plan;
    if (dash == null || plan == null) return;

    final currentLog = dash.todayLog ?? WellnessDailyLog(logDate: DateTime.now());
    state = state.copyWith(isSubmittingLog: true);

    try {
      final serverLog = await _api.upsertDailyLog(
        plan.id,
        UpsertWellnessDailyLogRequest(
          logDate: currentLog.logDate,
          ateAtLocal: currentLog.ateAtLocal,
          waterMl: currentLog.waterMl,
          workoutMinutes: currentLog.workoutMinutes,
          workoutType: currentLog.workoutType,
          currentWeightKg: weightKg,
          notes: currentLog.notes,
        ),
      );
      final weightProgress = await _api.getWeightProgress(plan.id);
      state = state.copyWith(
        dashboard: state.dashboard?.copyWith(
          todayLog: serverLog,
          weightProgress: weightProgress,
        ),
        isSubmittingLog: false,
        actionMessage: 'Đã cập nhật cân nặng: ${weightKg.toStringAsFixed(1)} kg',
      );
    } catch (e) {
      state = state.copyWith(isSubmittingLog: false);
    }
  }

  Future<void> completeTask(String taskId) async {
    final dash = state.dashboard;
    final plan = dash?.plan;
    if (dash == null || plan == null) return;

    final tasks = List<WellnessDailyTask>.from(dash.todayTasks);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final target = tasks[idx];
    final nextStatus = !target.isCompleted;

    // Optimistic
    tasks[idx] = target.copyWith(
      isCompleted: nextStatus,
      completedAt: nextStatus ? DateTime.now() : null,
    );
    state = state.copyWith(
      dashboard: dash.copyWith(todayTasks: tasks),
    );

    try {
      final updatedTask = await _api.completeTask(plan.id, taskId);
      tasks[idx] = updatedTask;
      state = state.copyWith(
        dashboard: state.dashboard?.copyWith(todayTasks: tasks),
      );
    } catch (_) {}
  }

  Future<void> askMoodCoach(WellnessCoachMoodRequest request) async {
    final dash = state.dashboard;
    final plan = dash?.plan;
    if (dash == null || plan == null) return;

    state = state.copyWith(isCoachLoading: true);
    try {
      final reply = await _api.askMoodCoach(plan.id, request);
      state = state.copyWith(
        isCoachLoading: false,
        lastCoachReply: reply,
      );
    } catch (e) {
      state = state.copyWith(isCoachLoading: false);
    }
  }

  Future<void> generateMeal(WellnessCoachMealRequest request) async {
    final dash = state.dashboard;
    final plan = dash?.plan;
    if (dash == null || plan == null) return;

    state = state.copyWith(isCoachLoading: true);
    try {
      final meal = await _api.generateMeal(plan.id, request);
      state = state.copyWith(
        isCoachLoading: false,
        lastMealSuggestion: meal,
      );
    } catch (e) {
      state = state.copyWith(isCoachLoading: false);
    }
  }

  Future<void> savePlan(UpsertWellnessPlanRequest request) async {
    state = state.copyWith(status: WellnessStatus.loading);
    try {
      await _api.upsertPlan(request);
      await loadDashboard();
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : AppFailure(
              type: AppFailureType.unknown,
              message: e.toString(),
            );
      state = state.copyWith(
        status: WellnessStatus.failure,
        failure: failure,
      );
    }
  }

  Future<void> updateSchedule(UpdateWellnessScheduleRequest request) async {
    final plan = state.dashboard?.plan;
    if (plan == null) return;

    state = state.copyWith(status: WellnessStatus.loading);
    try {
      await _api.updateSchedule(plan.id, request);
      await loadDashboard();
    } catch (e) {
      final failure = e is AppFailure
          ? e
          : AppFailure(
              type: AppFailureType.unknown,
              message: e.toString(),
            );
      state = state.copyWith(
        status: WellnessStatus.failure,
        failure: failure,
      );
    }
  }

  Future<void> loadTimeline({int days = 30}) async {
    final plan = state.dashboard?.plan;
    if (plan == null) return;

    try {
      final timeline = await _api.getProgressTimeline(plan.id, days: days);
      state = state.copyWith(timeline: timeline);
    } catch (_) {}
  }
}
