import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final courseDetailRepositoryProvider = Provider<CourseDetailRepository>((ref) {
  return CourseDetailRepository(api: ref.read(learningApiProvider));
});

class CourseDetailRepository {
  const CourseDetailRepository({required LearningApi api}) : _api = api;

  final LearningApi _api;

  Future<CourseDetailResult> loadCourseDetail(String courseId) async {
    final course = await _api.getCourse(courseId);
    final progress = await _captureProgress(courseId);
    return CourseDetailResult(
      course: course,
      progress: progress.data,
      progressIssue: progress.failure == null
          ? null
          : LearningSectionIssue(failure: progress.failure!),
    );
  }

  Future<LessonDetailResult> loadLesson({
    required String courseId,
    required String lessonPartId,
  }) async {
    final detail = await loadCourseDetail(courseId);
    final located = _findPart(detail.course, lessonPartId);
    if (located == null) {
      throw const AppFailure(
        type: AppFailureType.notFound,
        message: 'Lesson was not found.',
      );
    }

    final partProgress = detail.progress?.progressFor(lessonPartId);
    if (detail.progress == null && !located.part.isPreview) {
      final failure = detail.progressIssue?.failure;
      if (failure != null &&
          failure.type != AppFailureType.forbidden &&
          failure.type != AppFailureType.notFound) {
        throw failure;
      }
      throw const AppFailure(
        type: AppFailureType.forbidden,
        message: 'You do not have access to this lesson.',
      );
    }

    return LessonDetailResult(
      course: detail.course,
      lesson: located.lesson,
      part: located.part,
      progress: detail.progress,
      partProgress: partProgress,
      progressIssue: detail.progressIssue,
    );
  }

  Future<LessonDetailResult> markLessonComplete({
    required String courseId,
    required String lessonPartId,
  }) async {
    await _api.markLessonComplete(
      courseId: courseId,
      lessonPartId: lessonPartId,
    );
    return loadLesson(courseId: courseId, lessonPartId: lessonPartId);
  }

  Future<_ProgressResult> _captureProgress(String courseId) async {
    try {
      return _ProgressResult(data: await _api.getCourseProgress(courseId));
    } on AppFailure catch (failure) {
      return _ProgressResult(failure: failure);
    }
  }

  _LocatedPart? _findPart(LearningCourse course, String lessonPartId) {
    for (final lesson in course.lessons) {
      for (final part in lesson.parts) {
        if (part.id == lessonPartId) {
          return _LocatedPart(lesson: lesson, part: part);
        }
      }
    }
    return null;
  }
}

class _ProgressResult {
  const _ProgressResult({this.data, this.failure});

  final LearningCourseProgress? data;
  final AppFailure? failure;
}

class _LocatedPart {
  const _LocatedPart({required this.lesson, required this.part});

  final LearningLesson lesson;
  final LearningLessonPart part;
}
