import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/data/running_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RunningState {
  const RunningState({
    this.isLoading = false,
    this.summary = const RunningSummary(),
    this.activities = const [],
    this.totalCount = 0,
    this.availableGoals = const [
      RunningGoal(id: 'goal_health_2026', title: 'Sức khỏe 2026', activitiesCount: 3),
      RunningGoal(id: 'goal_change_21_days', title: '21 ngày thay đổi', activitiesCount: 5),
      RunningGoal(id: 'goal_balanced_living', title: 'Sống cân bằng', activitiesCount: 2),
    ],
    this.selectedGoalId,
    this.errorMessage,
  });

  final bool isLoading;
  final RunningSummary summary;
  final List<RunningActivity> activities;
  final int totalCount;
  final List<RunningGoal> availableGoals;
  final String? selectedGoalId;
  final String? errorMessage;

  RunningGoal? get selectedGoal {
    for (final g in availableGoals) {
      if (g.id == selectedGoalId) return g;
    }
    return null;
  }

  List<RunningBadge> get badges {
    final unlocked = summary.unlockedBadges.toSet();
    // Count per badge from activities
    final counts = <String, int>{};
    for (final act in activities) {
      for (final b in act.badgesEarned) {
        counts[b] = (counts[b] ?? 0) + 1;
      }
    }
    // Energy heart count
    if (summary.effectiveTotalEnergy > 0) {
      counts['badge_heart_energy'] = summary.effectiveTotalEnergy;
      unlocked.add('badge_heart_energy');
    }
    // Runs count
    if (summary.totalRunsCount >= 5) {
      counts['badge_silver'] = summary.totalRunsCount ~/ 5;
      unlocked.add('badge_silver');
    }
    if (summary.totalRunsCount >= 10) {
      counts['badge_gold'] = summary.totalRunsCount ~/ 10;
      unlocked.add('badge_gold');
    }

    return RunningBadgeCatalog.getAllBadges(
      unlockedIds: unlocked,
      counts: counts,
    );
  }

  RunningState copyWith({
    bool? isLoading,
    RunningSummary? summary,
    List<RunningActivity>? activities,
    int? totalCount,
    List<RunningGoal>? availableGoals,
    String? selectedGoalId,
    String? errorMessage,
  }) {
    return RunningState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      activities: activities ?? this.activities,
      totalCount: totalCount ?? this.totalCount,
      availableGoals: availableGoals ?? this.availableGoals,
      selectedGoalId: selectedGoalId ?? this.selectedGoalId,
      errorMessage: errorMessage,
    );
  }
}

final runningControllerProvider =
    StateNotifierProvider<RunningController, RunningState>((ref) {
  RunningRepository? repo;
  try {
    repo = ref.watch(runningRepositoryProvider);
  } catch (_) {
    // In tests or offline without app config initialized
  }
  return RunningController(repo);
});

class RunningController extends StateNotifier<RunningState> {
  RunningController([this._repository]) : super(const RunningState());

  final RunningRepository? _repository;
  bool _hasLoaded = false;

  Future<void> ensureLoaded() async {
    if (!_hasLoaded && _repository != null) {
      _hasLoaded = true;
      await load();
    }
  }

  Future<void> load() async {
    final repo = _repository;
    if (repo == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summaryFuture = repo.getSummary();
      final activitiesFuture = repo.getActivities(page: 1, pageSize: 30);

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

  void selectGoal(String? goalId) {
    state = state.copyWith(selectedGoalId: goalId);
  }

  void addGoal(String title) {
    if (title.trim().isEmpty) return;
    final newGoal = RunningGoal(
      id: 'goal_custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      activitiesCount: 0,
    );
    final updated = List<RunningGoal>.from(state.availableGoals)..add(newGoal);
    state = state.copyWith(
      availableGoals: updated,
      selectedGoalId: newGoal.id,
    );
  }

  Future<bool> logManualRun({
    required double distanceKm,
    required int durationSeconds,
    DateTime? activityDate,
    String? title,
    String? notes,
  }) async {
    final repo = _repository;
    if (repo == null) return false;
    try {
      final dto = CreateRunningActivityDto(
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
        activityDate: activityDate ?? DateTime.now(),
        title: title ?? 'Chạy bộ',
        notes: notes,
        trackingMode: 'MANUAL',
        energyEarned: distanceKm.floor(),
        linkedGoalId: state.selectedGoalId,
      );
      await repo.createActivity(dto);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRun(String id) async {
    final repo = _repository;
    if (repo == null) return false;
    try {
      final success = await repo.deleteActivity(id);
      if (success) {
        await load();
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}
