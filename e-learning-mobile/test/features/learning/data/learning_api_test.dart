import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/queued_dio_adapter.dart';

void main() {
  group('LearningApi', () {
    late QueuedDioAdapter adapter;
    late LearningApi api;

    setUp(() {
      adapter = QueuedDioAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api'))
        ..httpClientAdapter = adapter;
      api = LearningApi(
        apiClient: ApiClient(dio),
        errorMapper: const DioErrorMapper(),
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
      );
    });

    test(
      'requests published courses and parses confirmed course fields',
      () async {
        adapter.enqueue(
          method: 'GET',
          path: '/courses',
          statusCode: 200,
          body: [
            {
              'id': 'course-1',
              'title': 'Course',
              'description': '<p>Description</p>',
              'price': 150000,
              'isFree': false,
              'isPublished': true,
              'defaultAccessDurationDays': 30,
              'learningOutcomes': ['Outcome'],
              'createdAt': '2026-01-01T00:00:00Z',
              'thumbnailUrl': '/images/course.png',
              'lecturer': {'fullName': 'Giảng viên A'},
            },
          ],
        );

        final courses = await api.getPublishedCourses();

        final request = adapter.lastRequest('GET', '/courses');
        expect(request.queryParameters['isPublished'], true);
        expect(courses.single.title, 'Course');
        expect(courses.single.description, '<p>Description</p>');
        expect(courses.single.price, 150000);
        expect(courses.single.isFree, isFalse);
        expect(courses.single.isPublished, isTrue);
        expect(courses.single.defaultAccessDurationDays, 30);
        expect(courses.single.learningOutcomes, ['Outcome']);
        expect(courses.single.instructorName, 'Giảng viên A');
        expect(
          courses.single.thumbnailUrl,
          'https://api.example.com/images/course.png',
        );
      },
    );

    test('parses nullable and missing optional course fields', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/courses',
        statusCode: 200,
        body: [
          {
            'id': 'course-1',
            'title': 'Course',
            'description': null,
            'price': 0,
            'isFree': true,
            'isPublished': true,
            'createdAt': '2026-01-01T00:00:00Z',
          },
        ],
      );

      final courses = await api.getPublishedCourses();

      expect(courses.single.description, isNull);
      expect(courses.single.thumbnailUrl, isNull);
      expect(courses.single.instructorName, isNull);
      expect(courses.single.defaultAccessDurationDays, isNull);
      expect(courses.single.learningOutcomes, isEmpty);
    });

    test('parses confirmed enrollment fields', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/enrollments',
        statusCode: 200,
        body: [
          {
            'id': 'enrollment-1',
            'courseId': 'course-1',
            'courseTitle': 'Course',
            'courseThumbnail': '/thumb.png',
            'enrolledAt': '2026-01-01T00:00:00Z',
            'progressPercentage': 40,
            'completedAt': null,
            'lastAccessedAt': '2026-01-02T00:00:00Z',
            'accessDurationDays': 30,
            'accessExpiresAt': '2026-02-01T00:00:00Z',
            'isExpired': false,
            'status': 'ACTIVE',
          },
        ],
      );

      final enrollments = await api.getEnrollments();

      expect(enrollments.single.courseId, 'course-1');
      expect(enrollments.single.progressPercentage, 40);
      expect(
        enrollments.single.courseThumbnail,
        'https://api.example.com/thumb.png',
      );
      expect(enrollments.single.completedAt, isNull);
      expect(enrollments.single.status, 'ACTIVE');
    });

    test('parses active category fields', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/categories/active',
        statusCode: 200,
        body: [
          {
            'id': 'category-1',
            'name': 'Dinh dưỡng',
            'description': null,
            'order': 1,
            'isActive': true,
            'createdAt': '2026-01-01T00:00:00Z',
          },
        ],
      );

      final categories = await api.getActiveCategories();

      expect(categories.single.name, 'Dinh dưỡng');
      expect(categories.single.order, 1);
      expect(categories.single.isActive, isTrue);
    });

    test('malformed course response maps to AppFailure', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/courses',
        statusCode: 200,
        body: {'unexpected': true},
      );

      await expectLater(
        api.getPublishedCourses,
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.type,
            'type',
            AppFailureType.malformedResponse,
          ),
        ),
      );
    });

    test('server errors map to AppFailure', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/courses',
        statusCode: 500,
        body: {'message': 'Failed to fetch courses'},
      );

      await expectLater(
        api.getPublishedCourses,
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.type,
            'type',
            AppFailureType.server,
          ),
        ),
      );
    });

    test('parses course detail lessons and parts', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/courses/11111111-1111-1111-1111-111111111111',
        statusCode: 200,
        body: _courseDetailJson(),
      );

      final course = await api.getCourse(
        '11111111-1111-1111-1111-111111111111',
      );

      expect(course.lessons.single.title, 'Bắt đầu học');
      expect(course.lessons.single.parts.single.title, 'Tổng quan nhịn ăn');
      expect(course.lessons.single.parts.single.type, 'Video');
      expect(course.lessons.single.parts.single.videoDuration, 180);
      expect(
        course.lessons.single.parts.single.playbackUrl,
        'https://video.example.com/play.m3u8',
      );
    });

    test('parses course progress response', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/enrollments/11111111-1111-1111-1111-111111111111/progress',
        statusCode: 200,
        body: {
          'enrollmentId': 'enrollment-1',
          'progressPercentage': 50,
          'completedParts': 1,
          'totalParts': 2,
          'completedAt': null,
          'accessDurationDays': 30,
          'accessExpiresAt': '2026-02-01T00:00:00Z',
          'isExpired': false,
          'partProgress': [
            {
              'lessonPartId': '33333333-3333-3333-3333-333333333333',
              'lessonPartTitle': 'Tổng quan nhịn ăn',
              'isCompleted': true,
              'watchedDuration': 180,
              'completedAt': '2026-01-03T00:00:00Z',
              'lastWatchedAt': '2026-01-03T00:00:00Z',
            },
          ],
        },
      );

      final progress = await api.getCourseProgress(
        '11111111-1111-1111-1111-111111111111',
      );

      expect(progress.progressPercentage, 50);
      expect(progress.completedParts, 1);
      expect(progress.partProgress.single.isCompleted, isTrue);
    });

    test('marks lesson part complete using confirmed endpoint', () async {
      adapter.enqueue(
        method: 'POST',
        path:
            '/enrollments/11111111-1111-1111-1111-111111111111/lessons/33333333-3333-3333-3333-333333333333/complete',
        statusCode: 200,
        body: {'message': 'Lesson marked as complete'},
      );

      await api.markLessonComplete(
        courseId: '11111111-1111-1111-1111-111111111111',
        lessonPartId: '33333333-3333-3333-3333-333333333333',
      );

      expect(
        adapter.lastRequest(
          'POST',
          '/enrollments/11111111-1111-1111-1111-111111111111/lessons/33333333-3333-3333-3333-333333333333/complete',
        ),
        isNotNull,
      );
    });
  });
}

Map<String, Object?> _courseDetailJson() {
  return {
    'id': '11111111-1111-1111-1111-111111111111',
    'title': 'Nhập môn nhịn ăn chữa lành',
    'description': '<p>Nội dung nền tảng.</p>',
    'price': 0,
    'isFree': true,
    'lecturerId': '99999999-9999-9999-9999-999999999999',
    'lecturer': {'fullName': 'Giảng viên An'},
    'thumbnailUrl': null,
    'isPublished': true,
    'defaultAccessDurationDays': 30,
    'learningOutcomes': ['Hiểu nguyên tắc cơ bản'],
    'createdAt': '2026-01-01T00:00:00Z',
    'lessons': [
      {
        'id': '22222222-2222-2222-2222-222222222222',
        'title': 'Bắt đầu học',
        'description': 'Tổng quan',
        'thumbnailUrl': null,
        'categoryName': null,
        'createdAt': '2026-01-02T00:00:00Z',
        'updatedAt': null,
        'parts': [
          {
            'id': '33333333-3333-3333-3333-333333333333',
            'title': 'Tổng quan nhịn ăn',
            'type': 'Video',
            'orderIndex': 1,
            'isPreview': false,
            'videoId': null,
            'videoDuration': 180,
            'playbackUrl': 'https://video.example.com/play.m3u8',
            'documentId': null,
            'documentUrl': null,
            'documentFileName': null,
            'content': '<p>Phần nội dung bài học.</p>',
          },
        ],
      },
    ],
  };
}
