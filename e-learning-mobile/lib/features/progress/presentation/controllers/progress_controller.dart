import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/services/home_widget_service.dart';
import 'package:e_learning_mobile/features/progress/data/models/progress_models.dart';
import 'package:e_learning_mobile/features/progress/data/progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProgressStatus { initial, loading, success, failure }

class ProgressState {
  const ProgressState({
    this.status = ProgressStatus.initial,
    this.summary,
    this.failure,
  });

  final ProgressStatus status;
  final LearningProgressSummary? summary;
  final AppFailure? failure;

  ProgressState copyWith({
    ProgressStatus? status,
    LearningProgressSummary? summary,
    AppFailure? failure,
  }) {
    return ProgressState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      failure: failure ?? this.failure,
    );
  }
}

final progressControllerProvider =
    StateNotifierProvider<ProgressController, ProgressState>((ref) {
      return ProgressController(ref.read(progressRepositoryProvider));
    });

class ProgressController extends StateNotifier<ProgressState> {
  ProgressController(this._repository) : super(const ProgressState());

  final ProgressRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: ProgressStatus.loading);
    try {
      final summary = await _repository.getProgressSummary();
      state = ProgressState(status: ProgressStatus.success, summary: summary);
      try {
        final todayStat =
            summary.weeklyStudyStats.where((s) => s.isToday).firstOrNull;
        await HomeWidgetService.instance.syncFromUserData(
          streakDays: summary.currentStreakDays,
          targetMinutes: todayStat?.goalMinutes,
          learnedMinutes: todayStat?.minutesLearned,
        );
      } catch (_) {}
    } on AppFailure catch (e) {
      state = ProgressState(status: ProgressStatus.failure, failure: e);
    } catch (e) {
      state = ProgressState(
        status: ProgressStatus.failure,
        failure: AppFailure(
          type: AppFailureType.unknown,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() => load();
}
