import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/learning/data/course_detail_repository.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';

const fakeCourseId = '11111111-1111-1111-1111-111111111111';
const fakeLessonId = '22222222-2222-2222-2222-222222222222';
const fakePartId = '33333333-3333-3333-3333-333333333333';
const fakePreviewPartId = '44444444-4444-4444-4444-444444444444';
const fakeDocumentPartId = '55555555-5555-5555-5555-555555555555';

class FakeCourseDetailRepository extends CourseDetailRepository {
  FakeCourseDetailRepository({
    this.detailResult,
    this.lessonResult,
    this.loadError,
    this.lessonError,
    this.completeError,
    this.onLoadDetail,
    this.onLoadLesson,
    this.onComplete,
  }) : super(api: _UnusedLearningApi());

  final CourseDetailResult? detailResult;
  final LessonDetailResult? lessonResult;
  final AppFailure? loadError;
  final AppFailure? lessonError;
  final AppFailure? completeError;
  final Future<CourseDetailResult> Function(String courseId)? onLoadDetail;
  final Future<LessonDetailResult> Function(String courseId, String partId)?
  onLoadLesson;
  final Future<LessonDetailResult> Function(String courseId, String partId)?
  onComplete;

  int detailCallCount = 0;
  int lessonCallCount = 0;
  int completeCallCount = 0;

  @override
  Future<CourseDetailResult> loadCourseDetail(String courseId) async {
    detailCallCount += 1;
    if (onLoadDetail != null) {
      return onLoadDetail!(courseId);
    }
    if (loadError != null) {
      throw loadError!;
    }
    return detailResult ?? fakeCourseDetailResult();
  }

  @override
  Future<LessonDetailResult> loadLesson({
    required String courseId,
    required String lessonPartId,
  }) async {
    lessonCallCount += 1;
    if (onLoadLesson != null) {
      return onLoadLesson!(courseId, lessonPartId);
    }
    if (lessonError != null) {
      throw lessonError!;
    }
    return lessonResult ?? fakeLessonDetailResult();
  }

  @override
  Future<LessonDetailResult> markLessonComplete({
    required String courseId,
    required String lessonPartId,
  }) async {
    completeCallCount += 1;
    if (onComplete != null) {
      return onComplete!(courseId, lessonPartId);
    }
    if (completeError != null) {
      throw completeError!;
    }
    return fakeLessonDetailResult(completed: true);
  }
}

CourseDetailResult fakeCourseDetailResult({
  LearningCourse? course,
  LearningCourseProgress? progress,
  LearningSectionIssue? progressIssue,
}) {
  return CourseDetailResult(
    course: course ?? fakeDetailCourse(),
    progress: progress ?? fakeCourseProgress(),
    progressIssue: progressIssue,
  );
}

LessonDetailResult fakeLessonDetailResult({
  LearningCourse? course,
  LearningLesson? lesson,
  LearningLessonPart? part,
  LearningCourseProgress? progress,
  bool completed = false,
}) {
  final resolvedCourse = course ?? fakeDetailCourse();
  final resolvedLesson = lesson ?? resolvedCourse.lessons.first;
  final resolvedPart = part ?? resolvedLesson.parts.first;
  final resolvedProgress =
      progress ??
      fakeCourseProgress(
        completedPartIds: completed ? [resolvedPart.id] : const [],
      );
  return LessonDetailResult(
    course: resolvedCourse,
    lesson: resolvedLesson,
    part: resolvedPart,
    progress: resolvedProgress,
    partProgress: resolvedProgress.progressFor(resolvedPart.id),
  );
}

LearningCourse fakeDetailCourse({
  List<LearningLesson>? lessons,
  String id = fakeCourseId,
}) {
  return LearningCourse(
    id: id,
    title: 'Nhập môn nhịn ăn chữa lành',
    description: '<p>Nội dung nền tảng cho hành trình học tập.</p>',
    price: 0,
    isFree: true,
    isPublished: true,
    createdAt: DateTime.utc(2026, 1, 1),
    learningOutcomes: const ['Hiểu nguyên tắc cơ bản'],
    instructorName: 'Giảng viên An',
    thumbnailUrl: null,
    defaultAccessDurationDays: 30,
    lessons: lessons ?? [fakeLesson()],
  );
}

LearningLesson fakeLesson({List<LearningLessonPart>? parts}) {
  return LearningLesson(
    id: fakeLessonId,
    title: 'Bắt đầu học',
    description: 'Tổng quan bài học',
    createdAt: DateTime.utc(2026, 1, 2),
    parts:
        parts ??
        [
          fakeLessonPart(),
          fakeDocumentPart(),
          fakeLessonPart(
            id: fakePreviewPartId,
            title: 'Nội dung xem thử',
            isPreview: true,
          ),
        ],
  );
}

LearningLessonPart fakeLessonPart({
  String id = fakePartId,
  String title = 'Tổng quan nhịn ăn',
  String type = 'Video',
  bool isPreview = false,
  String? playbackUrl = 'https://video.example.com/play.m3u8',
  String? content = '<p>Phần nội dung bài học.</p>',
}) {
  return LearningLessonPart(
    id: id,
    title: title,
    type: type,
    orderIndex: 1,
    isPreview: isPreview,
    videoDuration: 180,
    playbackUrl: playbackUrl,
    content: content,
  );
}

LearningLessonPart fakeDocumentPart({
  String id = fakeDocumentPartId,
  String title = 'Tài liệu hướng dẫn',
  String? documentUrl = 'https://cdn.example.com/documents/guide.pdf',
}) {
  return LearningLessonPart(
    id: id,
    title: title,
    type: 'Document',
    orderIndex: 2,
    isPreview: false,
    videoDuration: 0,
    documentId: '66666666-6666-6666-6666-666666666666',
    documentUrl: documentUrl,
    documentFileName: 'guide.pdf',
  );
}

LearningCourseProgress fakeCourseProgress({
  List<String> completedPartIds = const [],
}) {
  final completed = completedPartIds.contains(fakePartId);
  final documentCompleted = completedPartIds.contains(fakeDocumentPartId);
  return LearningCourseProgress(
    enrollmentId: 'enrollment-1',
    progressPercentage: completed || documentCompleted ? 33 : 0,
    completedParts: [
      completed,
      documentCompleted,
    ].where((value) => value).length,
    totalParts: 3,
    isExpired: false,
    accessExpiresAt: DateTime.utc(2026, 2, 1),
    partProgress: [
      LearningLessonProgress(
        lessonPartId: fakePartId,
        lessonPartTitle: 'Tổng quan nhịn ăn',
        isCompleted: completed,
        watchedDuration: completed ? 180 : 30,
        completedAt: completed ? DateTime.utc(2026, 1, 3) : null,
        lastWatchedAt: DateTime.utc(2026, 1, 3),
      ),
      LearningLessonProgress(
        lessonPartId: fakeDocumentPartId,
        lessonPartTitle: 'Tài liệu hướng dẫn',
        isCompleted: documentCompleted,
        watchedDuration: 0,
        completedAt: documentCompleted ? DateTime.utc(2026, 1, 4) : null,
        lastWatchedAt: DateTime.utc(1),
      ),
      LearningLessonProgress(
        lessonPartId: fakePreviewPartId,
        lessonPartTitle: 'Nội dung xem thử',
        isCompleted: false,
        watchedDuration: 0,
        lastWatchedAt: DateTime.utc(1),
      ),
    ],
  );
}

class _UnusedLearningApi extends LearningApi {
  _UnusedLearningApi()
    : super(
        apiClient: ApiClient(Dio()),
        errorMapper: const DioErrorMapper(),
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
      );
}
