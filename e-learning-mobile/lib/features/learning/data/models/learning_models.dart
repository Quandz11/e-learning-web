import 'package:e_learning_mobile/core/errors/app_failure.dart';

class LearningCourse {
  const LearningCourse({
    required this.id,
    required this.title,
    required this.price,
    required this.isFree,
    required this.isPublished,
    required this.createdAt,
    required this.learningOutcomes,
    this.description,
    this.instructorName,
    this.thumbnailUrl,
    this.defaultAccessDurationDays,
    this.lessons = const [],
  });

  final String id;
  final String title;
  final String? description;
  final num price;
  final bool isFree;
  final bool isPublished;
  final String? instructorName;
  final String? thumbnailUrl;
  final int? defaultAccessDurationDays;
  final List<String> learningOutcomes;
  final DateTime createdAt;
  final List<LearningLesson> lessons;

  List<LearningLessonPart> get orderedParts {
    return [for (final lesson in lessons) ...lesson.parts];
  }
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.thumbnailUrl,
    this.categoryName,
    this.updatedAt,
    this.parts = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<LearningLessonPart> parts;
}

class LearningLessonPart {
  const LearningLessonPart({
    required this.id,
    required this.title,
    required this.type,
    required this.orderIndex,
    required this.isPreview,
    required this.videoDuration,
    this.videoId,
    this.playbackUrl,
    this.documentId,
    this.documentUrl,
    this.documentFileName,
    this.content,
  });

  final String id;
  final String title;
  final String type;
  final int orderIndex;
  final bool isPreview;
  final String? videoId;
  final double videoDuration;
  final String? playbackUrl;
  final String? documentId;
  final String? documentUrl;
  final String? documentFileName;
  final String? content;

  bool get isVideo => type.trim().toLowerCase() == 'video';
  bool get isDocument => type.trim().toLowerCase() == 'document';
}

class LearningCourseProgress {
  const LearningCourseProgress({
    required this.enrollmentId,
    required this.progressPercentage,
    required this.completedParts,
    required this.totalParts,
    required this.isExpired,
    required this.partProgress,
    this.completedAt,
    this.accessDurationDays,
    this.accessExpiresAt,
  });

  final String enrollmentId;
  final int progressPercentage;
  final int completedParts;
  final int totalParts;
  final DateTime? completedAt;
  final int? accessDurationDays;
  final DateTime? accessExpiresAt;
  final bool isExpired;
  final List<LearningLessonProgress> partProgress;

  LearningLessonProgress? progressFor(String lessonPartId) {
    for (final progress in partProgress) {
      if (progress.lessonPartId == lessonPartId) {
        return progress;
      }
    }
    return null;
  }
}

class LearningLessonProgress {
  const LearningLessonProgress({
    required this.lessonPartId,
    required this.lessonPartTitle,
    required this.isCompleted,
    required this.watchedDuration,
    required this.lastWatchedAt,
    this.completedAt,
  });

  final String lessonPartId;
  final String lessonPartTitle;
  final bool isCompleted;
  final int watchedDuration;
  final DateTime? completedAt;
  final DateTime lastWatchedAt;
}

class CourseDetailResult {
  const CourseDetailResult({
    required this.course,
    this.progress,
    this.progressIssue,
  });

  final LearningCourse course;
  final LearningCourseProgress? progress;
  final LearningSectionIssue? progressIssue;
}

class LessonDetailResult {
  const LessonDetailResult({
    required this.course,
    required this.lesson,
    required this.part,
    this.progress,
    this.partProgress,
    this.progressIssue,
  });

  final LearningCourse course;
  final LearningLesson lesson;
  final LearningLessonPart part;
  final LearningCourseProgress? progress;
  final LearningLessonProgress? partProgress;
  final LearningSectionIssue? progressIssue;

  bool get canMarkComplete =>
      progress != null && partProgress?.isCompleted != true;
}

class LearningEnrollment {
  const LearningEnrollment({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.enrolledAt,
    required this.progressPercentage,
    required this.lastAccessedAt,
    required this.isExpired,
    required this.status,
    this.courseThumbnail,
    this.completedAt,
    this.accessDurationDays,
    this.accessExpiresAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String? courseThumbnail;
  final DateTime enrolledAt;
  final int progressPercentage;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;
  final int? accessDurationDays;
  final DateTime? accessExpiresAt;
  final bool isExpired;
  final String status;

  bool get isCompleted => progressPercentage >= 100 || completedAt != null;
}

class LearningCategory {
  const LearningCategory({
    required this.id,
    required this.name,
    required this.order,
    required this.isActive,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final int order;
  final bool isActive;
  final DateTime createdAt;
}

class LearningSectionIssue {
  const LearningSectionIssue({required this.failure});

  final AppFailure failure;
}

class LearningLoadResult {
  const LearningLoadResult({
    required this.courses,
    required this.enrollments,
    required this.categories,
    this.enrollmentIssue,
    this.categoryIssue,
  });

  final List<LearningCourse> courses;
  final List<LearningEnrollment> enrollments;
  final List<LearningCategory> categories;
  final LearningSectionIssue? enrollmentIssue;
  final LearningSectionIssue? categoryIssue;
}
