import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/home/data/home_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/queued_dio_adapter.dart';

void main() {
  group('HomeApi', () {
    late QueuedDioAdapter adapter;
    late HomeApi api;

    setUp(() {
      adapter = QueuedDioAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api'))
        ..httpClientAdapter = adapter;
      api = HomeApi(
        apiClient: ApiClient(dio),
        errorMapper: const DioErrorMapper(),
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
      );
    });

    test('parses published courses from direct list response', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/courses',
        statusCode: 200,
        body: [
          {
            'id': 'course-1',
            'title': 'Course',
            'price': 150000,
            'isFree': false,
            'isPublished': true,
            'createdAt': '2026-01-01T00:00:00Z',
            'thumbnailUrl': '/images/course.png',
            'lecturer': {'fullName': 'Giảng viên A'},
          },
        ],
      );

      final response = await api.getPublishedCourses();

      final request = adapter.lastRequest('GET', '/courses');
      expect(request.queryParameters['isPublished'], true);
      expect(response.single.title, 'Course');
      expect(
        response.single.thumbnailUrl,
        'https://api.example.com/images/course.png',
      );
      expect(response.single.instructorName, 'Giảng viên A');
    });

    test('parses nullable article fields from paged response', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/articles',
        statusCode: 200,
        body: {
          'items': [
            {
              'id': 'article-1',
              'title': 'Article',
              'slug': 'article',
              'excerpt': null,
              'featuredImageUrl': null,
              'categoryName': null,
              'isPublished': true,
              'publishedAt': null,
              'createdAt': '2026-01-01T00:00:00Z',
            },
          ],
          'total': 1,
          'page': 1,
          'pageSize': 4,
        },
      );

      final response = await api.getRecentArticles();

      expect(response.single.title, 'Article');
      expect(response.single.excerpt, isNull);
      expect(response.single.featuredImageUrl, isNull);
      expect(response.single.publishedAt, isNull);
    });

    test('parses enrollments and active categories', () async {
      adapter.enqueue(
        method: 'GET',
        path: '/enrollments',
        statusCode: 200,
        body: [
          {
            'id': 'enrollment-1',
            'courseId': 'course-1',
            'courseTitle': 'Course',
            'courseThumbnail': null,
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

      final enrollments = await api.getEnrollments();
      final categories = await api.getActiveCategories();

      expect(enrollments.single.progressPercentage, 40);
      expect(categories.single.name, 'Dinh dưỡng');
    });

    test('maps malformed primary response to AppFailure', () async {
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
  });
}
