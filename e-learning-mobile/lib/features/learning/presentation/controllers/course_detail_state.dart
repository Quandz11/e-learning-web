import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';

enum CourseDetailStatus { initial, loading, success, failure }

class CourseDetailState {
  const CourseDetailState({
    this.status = CourseDetailStatus.initial,
    this.course,
    this.progress,
    this.progressIssue,
    this.primaryFailure,
    this.refreshFailure,
    this.isRefreshing = false,
  });

  final CourseDetailStatus status;
  final LearningCourse? course;
  final LearningCourseProgress? progress;
  final LearningSectionIssue? progressIssue;
  final AppFailure? primaryFailure;
  final AppFailure? refreshFailure;
  final bool isRefreshing;

  bool get hasContent => course != null;

  bool get isInitialLoading =>
      status == CourseDetailStatus.loading && !hasContent && !isRefreshing;

  CourseDetailState copyWith({
    CourseDetailStatus? status,
    LearningCourse? course,
    LearningCourseProgress? progress,
    bool clearProgress = false,
    LearningSectionIssue? progressIssue,
    bool clearProgressIssue = false,
    AppFailure? primaryFailure,
    bool clearPrimaryFailure = false,
    AppFailure? refreshFailure,
    bool clearRefreshFailure = false,
    bool? isRefreshing,
  }) {
    return CourseDetailState(
      status: status ?? this.status,
      course: course ?? this.course,
      progress: clearProgress ? null : progress ?? this.progress,
      progressIssue: clearProgressIssue
          ? null
          : progressIssue ?? this.progressIssue,
      primaryFailure: clearPrimaryFailure
          ? null
          : primaryFailure ?? this.primaryFailure,
      refreshFailure: clearRefreshFailure
          ? null
          : refreshFailure ?? this.refreshFailure,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
