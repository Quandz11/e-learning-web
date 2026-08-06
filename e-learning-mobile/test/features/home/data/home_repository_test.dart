import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/home/data/home_api.dart';
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeRepository', () {
    test('selects the most recent incomplete enrollment', () async {
      final repository = HomeRepository(
        api: _FakeHomeApi(
          courses: [
            HomeCourse(
              id: 'course-1',
              title: 'Course',
              price: 100000,
              isFree: false,
              isPublished: true,
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          ],
          enrollments: [
            HomeEnrollment(
              id: 'completed',
              courseId: 'course-1',
              courseTitle: 'Completed',
              enrolledAt: DateTime.utc(2026, 1, 1),
              progressPercentage: 100,
              completedAt: DateTime.utc(2026, 1, 2),
              lastAccessedAt: DateTime.utc(2026, 1, 3),
              isExpired: false,
              status: 'ACTIVE',
            ),
            HomeEnrollment(
              id: 'in-progress',
              courseId: 'course-2',
              courseTitle: 'In progress',
              enrolledAt: DateTime.utc(2026, 1, 1),
              progressPercentage: 45,
              completedAt: null,
              lastAccessedAt: DateTime.utc(2026, 1, 5),
              isExpired: false,
              status: 'ACTIVE',
            ),
          ],
        ),
      );

      final result = await repository.loadHome();

      expect(result.continueLearning?.id, 'in-progress');
    });

    test(
      'preserves optional endpoint failures without hiding courses',
      () async {
        final repository = HomeRepository(
          api: _FakeHomeApi(
            courses: [
              HomeCourse(
                id: 'course-1',
                title: 'Course',
                price: 100000,
                isFree: false,
                isPublished: true,
                createdAt: DateTime.utc(2026, 1, 1),
              ),
            ],
            categories: const [
              HomeCategory(
                id: 'category-1',
                name: 'Danh mục',
                description: null,
                order: 1,
                isActive: true,
              ),
            ],
            categoriesFailure: const AppFailure(
              type: AppFailureType.server,
              message: 'Server error',
            ),
          ),
        );

        final result = await repository.loadHome();

        expect(result.featuredCourses, hasLength(1));
        expect(result.categoryIssue, isNotNull);
        expect(result.categories, isEmpty);
      },
    );

    test('rethrows primary course failures', () async {
      final repository = HomeRepository(
        api: _FakeHomeApi(
          coursesFailure: const AppFailure(
            type: AppFailureType.server,
            message: 'Server error',
          ),
        ),
      );

      await expectLater(
        repository.loadHome,
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.type,
            'type',
            AppFailureType.server,
          ),
        ),
      );
    });
  });
}

class _FakeHomeApi extends HomeApi {
  _FakeHomeApi({
    this.courses = const [],
    this.enrollments = const [],
    this.categories = const [],
    this.coursesFailure,
    this.categoriesFailure,
  }) : super(
         apiClient: ApiClient(Dio()),
         errorMapper: const DioErrorMapper(),
         apiBaseUrl: Uri.parse('https://api.example.com/api'),
       );

  final List<HomeCourse> courses;
  final List<HomeEnrollment> enrollments;
  final List<HomeCategory> categories;
  final AppFailure? coursesFailure;
  final AppFailure? categoriesFailure;

  @override
  Future<List<HomeCourse>> getPublishedCourses() async {
    if (coursesFailure != null) {
      throw coursesFailure!;
    }
    return courses;
  }

  @override
  Future<List<HomeEnrollment>> getEnrollments() async {
    return enrollments;
  }

  @override
  Future<List<HomeCategory>> getActiveCategories() async {
    if (categoriesFailure != null) {
      throw categoriesFailure!;
    }
    return categories;
  }

  @override
  Future<List<HomeArticle>> getRecentArticles({int pageSize = 4}) async {
    return const [];
  }

  @override
  Future<List<HomeTestimonial>> getActiveTestimonials() async {
    return const [];
  }
}
