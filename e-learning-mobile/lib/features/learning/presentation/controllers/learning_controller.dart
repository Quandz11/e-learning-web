import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final learningControllerProvider =
    StateNotifierProvider<LearningController, LearningState>((ref) {
      return LearningController(ref.read(learningRepositoryProvider));
    });

class LearningController extends StateNotifier<LearningState> {
  LearningController(this._repository) : super(const LearningState());

  final LearningRepository _repository;

  Future<void> ensureLoaded() async {
    if (state.status != LearningStatus.initial) {
      return;
    }
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    if (state.isInitialLoading || state.isRefreshing) {
      return;
    }

    if (refresh && state.status == LearningStatus.success) {
      state = state.copyWith(isRefreshing: true, clearRefreshFailure: true);
    } else {
      state = state.copyWith(
        status: LearningStatus.loading,
        isRefreshing: false,
        clearPrimaryFailure: true,
        clearRefreshFailure: true,
      );
    }

    if (!refresh && state.courses.isEmpty) {
      try {
        final cachedResult = await _repository.loadLearningFromCache();
        if (cachedResult != null && mounted && state.status == LearningStatus.loading) {
          state = LearningState(
            status: LearningStatus.success,
            courses: cachedResult.courses,
            enrollments: cachedResult.enrollments,
            categories: cachedResult.categories,
          );
        }
      } catch (_) {}
    }

    try {
      final result = await _repository.loadLearning();
      if (!mounted) {
        return;
      }

      state = LearningState(
        status: LearningStatus.success,
        courses: result.courses,
        enrollments: result.enrollments,
        categories: result.categories,
        enrollmentIssue: result.enrollmentIssue,
        categoryIssue: result.categoryIssue,
      );
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      _applyFailure(failure, refresh: refresh);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _applyFailure(
        AppFailure(
          type: AppFailureType.unknown,
          message: 'Something went wrong. Please try again.',
          originalCause: error,
        ),
        refresh: refresh,
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  void _applyFailure(AppFailure failure, {required bool refresh}) {
    if (refresh && state.hasLoadedContent) {
      state = state.copyWith(
        status: LearningStatus.success,
        isRefreshing: false,
        refreshFailure: failure,
        clearPrimaryFailure: true,
      );
      return;
    }

    state = state.copyWith(
      status: LearningStatus.failure,
      primaryFailure: failure,
      isRefreshing: false,
    );
  }
}
