import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_learning_repository.dart';

void main() {
  group('LearningRepository', () {
    test(
      'loads published courses, active enrollments, and active categories',
      () async {
        final api = _FakeLearningApi(
          courses: [
            _course(id: 'published', isPublished: true),
            _course(id: 'draft', isPublished: false),
          ],
          enrollments: [
            _enrollment(id: 'active', status: 'ACTIVE'),
            _enrollment(id: 'inactive', status: 'INACTIVE'),
          ],
          categories: [
            _category(id: 'second', order: 2),
            _category(id: 'first', order: 1),
            _category(id: 'inactive', isActive: false),
          ],
        );
        final repository = LearningRepository(api: api);

        final result = await repository.loadLearning();

        expect(result.courses.map((course) => course.id), ['published']);
        expect(result.enrollments.map((enrollment) => enrollment.id), [
          'active',
        ]);
        expect(result.categories.map((category) => category.id), [
          'first',
          'second',
        ]);
      },
    );

    test('enrollment failure is isolated when courses load', () async {
      final repository = LearningRepository(
        api: _FakeLearningApi(
          courses: [_course()],
          enrollmentsError: const AppFailure(
            type: AppFailureType.server,
            message: 'Enrollment failure',
          ),
          categories: [_category()],
        ),
      );

      final result = await repository.loadLearning();

      expect(result.courses, hasLength(1));
      expect(result.enrollments, isEmpty);
      expect(result.enrollmentIssue?.failure.type, AppFailureType.server);
    });

    test('category failure is isolated when courses load', () async {
      final repository = LearningRepository(
        api: _FakeLearningApi(
          courses: [_course()],
          enrollments: [_enrollment()],
          categoriesError: const AppFailure(
            type: AppFailureType.timeout,
            message: 'Timeout',
          ),
        ),
      );

      final result = await repository.loadLearning();

      expect(result.courses, hasLength(1));
      expect(result.categories, isEmpty);
      expect(result.categoryIssue?.failure.type, AppFailureType.timeout);
    });

    test('primary course failure is rethrown', () async {
      final repository = LearningRepository(
        api: _FakeLearningApi(
          coursesError: const AppFailure(
            type: AppFailureType.networkUnavailable,
            message: 'Offline',
          ),
        ),
      );

      await expectLater(
        repository.loadLearning,
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.type,
            'type',
            AppFailureType.networkUnavailable,
          ),
        ),
      );
    });

    test('fake repository returns deterministic fixture data', () async {
      final repository = FakeLearningRepository();

      final result = await repository.loadLearning();

      expect(result.courses, isNotEmpty);
      expect(result.enrollments, isNotEmpty);
      expect(result.categories, isNotEmpty);
      expect(repository.loadCallCount, 1);
    });
  });
}

LearningCourse _course({String id = 'course', bool isPublished = true}) {
  return LearningCourse(
    id: id,
    title: 'Course $id',
    price: 0,
    isFree: true,
    isPublished: isPublished,
    createdAt: DateTime.utc(2026, 1),
    learningOutcomes: const [],
  );
}

LearningEnrollment _enrollment({
  String id = 'enrollment',
  String status = 'ACTIVE',
}) {
  return LearningEnrollment(
    id: id,
    courseId: 'course-$id',
    courseTitle: 'Course $id',
    enrolledAt: DateTime.utc(2026, 1),
    progressPercentage: 10,
    lastAccessedAt: DateTime.utc(2026, 1, 2),
    isExpired: false,
    status: status,
  );
}

LearningCategory _category({
  String id = 'category',
  int order = 1,
  bool isActive = true,
}) {
  return LearningCategory(
    id: id,
    name: 'Category $id',
    order: order,
    isActive: isActive,
    createdAt: DateTime.utc(2026, 1),
  );
}

class _FakeLearningApi extends LearningApi {
  _FakeLearningApi({
    this.courses = const [],
    this.enrollments = const [],
    this.categories = const [],
    this.coursesError,
    this.enrollmentsError,
    this.categoriesError,
  }) : super(
         apiClient: ApiClient(Dio()),
         errorMapper: const DioErrorMapper(),
         apiBaseUrl: Uri.parse('https://api.example.com/api'),
       );

  final List<LearningCourse> courses;
  final List<LearningEnrollment> enrollments;
  final List<LearningCategory> categories;
  final AppFailure? coursesError;
  final AppFailure? enrollmentsError;
  final AppFailure? categoriesError;

  @override
  Future<List<LearningCourse>> getPublishedCourses() async {
    if (coursesError != null) {
      throw coursesError!;
    }
    return courses;
  }

  @override
  Future<List<LearningEnrollment>> getEnrollments() async {
    if (enrollmentsError != null) {
      throw enrollmentsError!;
    }
    return enrollments;
  }

  @override
  Future<List<LearningCategory>> getActiveCategories() async {
    if (categoriesError != null) {
      throw categoriesError!;
    }
    return categories;
  }
}
