import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/learning/data/course_detail_repository.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_course_detail_repository.dart';

void main() {
  group('CourseDetailRepository', () {
    test('loads course detail with progress', () async {
      final repository = FakeCourseDetailRepository();

      final result = await repository.loadCourseDetail(fakeCourseId);

      expect(result.course.id, fakeCourseId);
      expect(result.progress?.progressPercentage, 0);
      expect(repository.detailCallCount, 1);
    });

    test('loads lesson detail for accessible part', () async {
      final repository = FakeCourseDetailRepository();

      final result = await repository.loadLesson(
        courseId: fakeCourseId,
        lessonPartId: fakePartId,
      );

      expect(result.part.id, fakePartId);
      expect(result.canMarkComplete, isTrue);
    });

    test('rejects lesson when repository reports forbidden access', () async {
      final repository = CourseDetailRepository(
        api: _FakeApi(
          progressError: const AppFailure(
            type: AppFailureType.forbidden,
            message: 'Forbidden',
          ),
        ),
      );

      await expectLater(
        repository.loadLesson(courseId: fakeCourseId, lessonPartId: fakePartId),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.type,
            'type',
            AppFailureType.forbidden,
          ),
        ),
      );
    });

    test('marks part complete and reloads backend-confirmed state', () async {
      final repository = FakeCourseDetailRepository();

      final result = await repository.markLessonComplete(
        courseId: fakeCourseId,
        lessonPartId: fakePartId,
      );

      expect(result.partProgress?.isCompleted, isTrue);
      expect(repository.completeCallCount, 1);
    });
  });
}

class _FakeApi extends LearningApi {
  _FakeApi({this.progressError})
    : super(
        apiClient: ApiClient(Dio()),
        errorMapper: const DioErrorMapper(),
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
      );

  final AppFailure? progressError;

  @override
  Future<LearningCourse> getCourse(String courseId) async => fakeDetailCourse();

  @override
  Future<LearningCourseProgress> getCourseProgress(String courseId) async {
    final error = progressError;
    if (error != null) {
      throw error;
    }
    return fakeCourseProgress();
  }
}
