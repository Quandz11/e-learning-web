import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/data/running_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RunningState {
  const RunningState({
    this.isLoading = false,
    this.summary = const RunningSummary(),
    this.activities = const [],
    this.totalCount = 0,
    this.errorMessage,
  });

  final bool isLoading;
  final RunningSummary summary;
  final List<RunningActivity> activities;
  final int totalCount;
  final String? errorMessage;

  RunningState copyWith({
    bool? isLoading,
    RunningSummary? summary,
    List<RunningActivity>? activities,
    int? totalCount,
    String? errorMessage,
  }) {
    return RunningState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      activities: activities ?? this.activities,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage,
    );
  }
}

final runningControllerProvider =
    StateNotifierProvider<RunningController, RunningState>((ref) {
  return RunningController(ref.read(runningRepositoryProvider));
});

class RunningController extends StateNotifier<RunningState> {
  RunningController(this._repository) : super(const RunningState()) {
    load();
  }

  final RunningRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summaryFuture = _repository.getSummary();
      final activitiesFuture = _repository.getActivities(page: 1, pageSize: 30);

      final summary = await summaryFuture;
      final activitiesResult = await activitiesFuture;

      state = state.copyWith(
        isLoading: false,
        summary: summary,
        activities: activitiesResult.items,
        totalCount: activitiesResult.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() => load();

  Future<bool> logManualRun({
    required double distanceKm,
    required int durationSeconds,
    DateTime? activityDate,
    String? title,
    String? notes,
  }) async {
    try {
      final dto = CreateRunningActivityDto(
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
        activityDate: activityDate ?? DateTime.now(),
        title: title ?? 'Chạy bộ',
        notes: notes,
        trackingMode: 'MANUAL',
      );
      await _repository.createActivity(dto);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRun(String id) async {
    try {
      final success = await _repository.deleteActivity(id);
      if (success) {
        await load();
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}
