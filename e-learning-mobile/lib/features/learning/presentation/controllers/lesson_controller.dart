import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/course_detail_repository.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lessonControllerProvider = StateNotifierProvider.autoDispose
    .family<LessonController, LessonState, LessonRouteArgs>((ref, args) {
      return LessonController(
        courseId: args.courseId,
        lessonPartId: args.lessonPartId,
        repository: ref.read(courseDetailRepositoryProvider),
      );
    });

class LessonRouteArgs {
  const LessonRouteArgs({required this.courseId, required this.lessonPartId});

  final String courseId;
  final String lessonPartId;

  @override
  bool operator ==(Object other) {
    return other is LessonRouteArgs &&
        other.courseId == courseId &&
        other.lessonPartId == lessonPartId;
  }

  @override
  int get hashCode => Object.hash(courseId, lessonPartId);
}

class LessonController extends StateNotifier<LessonState> {
  LessonController({
    required String courseId,
    required String lessonPartId,
    required CourseDetailRepository repository,
  }) : _courseId = courseId,
       _lessonPartId = lessonPartId,
       _repository = repository,
       super(const LessonState());

  final String _courseId;
  final String _lessonPartId;
  final CourseDetailRepository _repository;

  Future<void> ensureLoaded() async {
    if (state.status != LessonStatus.initial) {
      return;
    }
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    if (state.isInitialLoading || state.isRefreshing || state.isCompleting) {
      return;
    }

    if (refresh && state.hasContent) {
      state = state.copyWith(isRefreshing: true, clearRefreshFailure: true);
    } else {
      state = state.copyWith(
        status: LessonStatus.loading,
        clearPrimaryFailure: true,
        clearRefreshFailure: true,
        clearCompletionFailure: true,
        isRefreshing: false,
      );
    }

    try {
      final detail = await _repository.loadLesson(
        courseId: _courseId,
        lessonPartId: _lessonPartId,
      );
      if (!mounted) {
        return;
      }
      state = LessonState(status: LessonStatus.success, detail: detail);
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

  Future<void> markComplete() async {
    final detail = state.detail;
    if (detail == null || !detail.canMarkComplete || state.isCompleting) {
      return;
    }

    state = state.copyWith(
      isCompleting: true,
      clearCompletionFailure: true,
      clearRefreshFailure: true,
    );

    try {
      final updated = await _repository.markLessonComplete(
        courseId: _courseId,
        lessonPartId: _lessonPartId,
      );
      if (!mounted) {
        return;
      }
      state = LessonState(status: LessonStatus.success, detail: updated);
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(isCompleting: false, completionFailure: failure);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isCompleting: false,
        completionFailure: AppFailure(
          type: AppFailureType.unknown,
          message: 'Something went wrong. Please try again.',
          originalCause: error,
        ),
      );
    }
  }

  void _applyFailure(AppFailure failure, {required bool refresh}) {
    if (refresh && state.hasContent) {
      state = state.copyWith(
        status: LessonStatus.success,
        refreshFailure: failure,
        isRefreshing: false,
        clearPrimaryFailure: true,
      );
      return;
    }

    state = state.copyWith(
      status: LessonStatus.failure,
      primaryFailure: failure,
      isRefreshing: false,
    );
  }
}
