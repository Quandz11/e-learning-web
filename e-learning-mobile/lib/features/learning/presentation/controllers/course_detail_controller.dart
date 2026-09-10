import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/course_detail_repository.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/course_detail_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final courseDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<CourseDetailController, CourseDetailState, String>((ref, courseId) {
      return CourseDetailController(
        courseId: courseId,
        repository: ref.read(courseDetailRepositoryProvider),
      );
    });

class CourseDetailController extends StateNotifier<CourseDetailState> {
  CourseDetailController({
    required String courseId,
    required CourseDetailRepository repository,
  }) : _courseId = courseId,
       _repository = repository,
       super(const CourseDetailState());

  final String _courseId;
  final CourseDetailRepository _repository;

  Future<void> ensureLoaded() async {
    if (state.status != CourseDetailStatus.initial) {
      return;
    }
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    if (state.isInitialLoading || state.isRefreshing) {
      return;
    }

    if (refresh && state.hasContent) {
      state = state.copyWith(isRefreshing: true, clearRefreshFailure: true);
    } else {
      state = state.copyWith(
        status: CourseDetailStatus.loading,
        clearPrimaryFailure: true,
        clearRefreshFailure: true,
        isRefreshing: false,
      );
    }

    try {
      final result = await _repository.loadCourseDetail(_courseId);
      if (!mounted) {
        return;
      }
      state = CourseDetailState(
        status: CourseDetailStatus.success,
        course: result.course,
        progress: result.progress,
        progressIssue: result.progressIssue,
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

  Future<bool> enroll() async {
    try {
      await _repository.enrollInCourse(_courseId);
      await load(refresh: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _applyFailure(AppFailure failure, {required bool refresh}) {
    if (refresh && state.hasContent) {
      state = state.copyWith(
        status: CourseDetailStatus.success,
        refreshFailure: failure,
        isRefreshing: false,
        clearPrimaryFailure: true,
      );
      return;
    }

    state = state.copyWith(
      status: CourseDetailStatus.failure,
      primaryFailure: failure,
      isRefreshing: false,
    );
  }
}
