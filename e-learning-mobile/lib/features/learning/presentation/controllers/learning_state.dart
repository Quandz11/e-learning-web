import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';

enum LearningStatus { initial, loading, success, failure }

class LearningState {
  const LearningState({
    this.status = LearningStatus.initial,
    this.courses = const [],
    this.enrollments = const [],
    this.categories = const [],
    this.primaryFailure,
    this.refreshFailure,
    this.enrollmentIssue,
    this.categoryIssue,
    this.isRefreshing = false,
  });

  final LearningStatus status;
  final List<LearningCourse> courses;
  final List<LearningEnrollment> enrollments;
  final List<LearningCategory> categories;
  final AppFailure? primaryFailure;
  final AppFailure? refreshFailure;
  final LearningSectionIssue? enrollmentIssue;
  final LearningSectionIssue? categoryIssue;
  final bool isRefreshing;

  bool get hasLoadedContent =>
      courses.isNotEmpty || enrollments.isNotEmpty || categories.isNotEmpty;

  bool get isInitialLoading =>
      status == LearningStatus.loading && !hasLoadedContent && !isRefreshing;

  LearningState copyWith({
    LearningStatus? status,
    List<LearningCourse>? courses,
    List<LearningEnrollment>? enrollments,
    List<LearningCategory>? categories,
    AppFailure? primaryFailure,
    bool clearPrimaryFailure = false,
    AppFailure? refreshFailure,
    bool clearRefreshFailure = false,
    LearningSectionIssue? enrollmentIssue,
    bool clearEnrollmentIssue = false,
    LearningSectionIssue? categoryIssue,
    bool clearCategoryIssue = false,
    bool? isRefreshing,
  }) {
    return LearningState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      enrollments: enrollments ?? this.enrollments,
      categories: categories ?? this.categories,
      primaryFailure: clearPrimaryFailure
          ? null
          : primaryFailure ?? this.primaryFailure,
      refreshFailure: clearRefreshFailure
          ? null
          : refreshFailure ?? this.refreshFailure,
      enrollmentIssue: clearEnrollmentIssue
          ? null
          : enrollmentIssue ?? this.enrollmentIssue,
      categoryIssue: clearCategoryIssue
          ? null
          : categoryIssue ?? this.categoryIssue,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
