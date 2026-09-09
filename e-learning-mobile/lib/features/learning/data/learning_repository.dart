import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/learning_api.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(api: ref.read(learningApiProvider));
});

class LearningRepository {
  const LearningRepository({required LearningApi api}) : _api = api;

  final LearningApi _api;

  Future<LearningLoadResult> loadLearning() async {
    final courses = await _api.getPublishedCourses();
    final enrollments = await _captureOptional(_api.getEnrollments);
    final categories = await _captureOptional(_api.getActiveCategories);

    return LearningLoadResult(
      courses: courses
          .where((course) => course.isPublished)
          .toList(growable: false),
      enrollments: enrollments.data
          .where((enrollment) => enrollment.status == 'ACTIVE')
          .toList(growable: false),
      categories:
          categories.data
              .where((category) => category.isActive)
              .toList(growable: false)
            ..sort((left, right) => left.order.compareTo(right.order)),
      enrollmentIssue: enrollments.failure == null
          ? null
          : LearningSectionIssue(failure: enrollments.failure!),
      categoryIssue: categories.failure == null
          ? null
          : LearningSectionIssue(failure: categories.failure!),
    );
  }

  Future<_OptionalResult<T>> _captureOptional<T>(
    Future<List<T>> Function() action,
  ) async {
    try {
      return _OptionalResult<T>(data: await action());
    } on AppFailure catch (failure) {
      return _OptionalResult<T>(data: const [], failure: failure);
    } catch (error) {
      return _OptionalResult<T>(
        data: const [],
        failure: AppFailure(
          type: AppFailureType.unknown,
          message: 'Something went wrong. Please try again.',
          originalCause: error,
        ),
      );
    }
  }
}

class _OptionalResult<T> {
  const _OptionalResult({required this.data, this.failure});

  final List<T> data;
  final AppFailure? failure;
}
