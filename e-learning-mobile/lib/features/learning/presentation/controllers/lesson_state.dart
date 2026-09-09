import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';

enum LessonStatus { initial, loading, success, failure }

class LessonState {
  const LessonState({
    this.status = LessonStatus.initial,
    this.detail,
    this.primaryFailure,
    this.refreshFailure,
    this.completionFailure,
    this.isRefreshing = false,
    this.isCompleting = false,
  });

  final LessonStatus status;
  final LessonDetailResult? detail;
  final AppFailure? primaryFailure;
  final AppFailure? refreshFailure;
  final AppFailure? completionFailure;
  final bool isRefreshing;
  final bool isCompleting;

  bool get hasContent => detail != null;

  bool get isInitialLoading =>
      status == LessonStatus.loading && !hasContent && !isRefreshing;

  LessonState copyWith({
    LessonStatus? status,
    LessonDetailResult? detail,
    AppFailure? primaryFailure,
    bool clearPrimaryFailure = false,
    AppFailure? refreshFailure,
    bool clearRefreshFailure = false,
    AppFailure? completionFailure,
    bool clearCompletionFailure = false,
    bool? isRefreshing,
    bool? isCompleting,
  }) {
    return LessonState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      primaryFailure: clearPrimaryFailure
          ? null
          : primaryFailure ?? this.primaryFailure,
      refreshFailure: clearRefreshFailure
          ? null
          : refreshFailure ?? this.refreshFailure,
      completionFailure: clearCompletionFailure
          ? null
          : completionFailure ?? this.completionFailure,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }
}
