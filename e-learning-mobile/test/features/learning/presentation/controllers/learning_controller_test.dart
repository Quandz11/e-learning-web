import 'dart:async';

import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_learning_repository.dart';

void main() {
  group('LearningController', () {
    test('starts with initial state', () {
      final controller = LearningController(FakeLearningRepository());

      expect(controller.state.status, LearningStatus.initial);
      expect(controller.state.courses, isEmpty);
      expect(controller.state.enrollments, isEmpty);
      expect(controller.state.categories, isEmpty);
    });

    test('loads learning content successfully', () async {
      final controller = LearningController(FakeLearningRepository());

      await controller.load();

      expect(controller.state.status, LearningStatus.success);
      expect(controller.state.courses, isNotEmpty);
      expect(controller.state.enrollments, isNotEmpty);
      expect(controller.state.categories, isNotEmpty);
    });

    test('handles empty enrollment as successful content', () async {
      final controller = LearningController(
        FakeLearningRepository(
          result: fakeLearningLoadResult(enrollments: const []),
        ),
      );

      await controller.load();

      expect(controller.state.status, LearningStatus.success);
      expect(controller.state.enrollments, isEmpty);
      expect(controller.state.courses, isNotEmpty);
    });

    test('captures optional section failures', () async {
      final controller = LearningController(
        FakeLearningRepository(
          result: fakeLearningLoadResult(
            enrollments: const [],
            categories: const [],
            enrollmentIssue: const LearningSectionIssue(
              failure: AppFailure(
                type: AppFailureType.server,
                message: 'Enrollment error',
              ),
            ),
            categoryIssue: const LearningSectionIssue(
              failure: AppFailure(
                type: AppFailureType.timeout,
                message: 'Category timeout',
              ),
            ),
          ),
        ),
      );

      await controller.load();

      expect(controller.state.status, LearningStatus.success);
      expect(
        controller.state.enrollmentIssue?.failure.type,
        AppFailureType.server,
      );
      expect(
        controller.state.categoryIssue?.failure.type,
        AppFailureType.timeout,
      );
    });

    test('primary course failure moves to failure state', () async {
      final controller = LearningController(
        FakeLearningRepository(
          error: const AppFailure(
            type: AppFailureType.server,
            message: 'Server error',
          ),
        ),
      );

      await controller.load();

      expect(controller.state.status, LearningStatus.failure);
      expect(controller.state.primaryFailure?.type, AppFailureType.server);
    });

    test('refresh retains content when refresh fails', () async {
      var fail = false;
      final controller = LearningController(
        FakeLearningRepository(
          onLoad: () async {
            if (fail) {
              throw const AppFailure(
                type: AppFailureType.timeout,
                message: 'Timeout',
              );
            }
            return fakeLearningLoadResult();
          },
        ),
      );

      await controller.load();
      fail = true;
      await controller.refresh();

      expect(controller.state.status, LearningStatus.success);
      expect(controller.state.courses, isNotEmpty);
      expect(controller.state.refreshFailure?.type, AppFailureType.timeout);
    });

    test('prevents duplicate concurrent refreshes', () async {
      final completer = Completer<LearningLoadResult>();
      final repository = FakeLearningRepository(onLoad: () => completer.future);
      final controller = LearningController(repository);

      unawaited(controller.load());
      await Future<void>.delayed(Duration.zero);
      unawaited(controller.load());

      expect(repository.loadCallCount, 1);

      completer.complete(fakeLearningLoadResult());
      await Future<void>.delayed(Duration.zero);
    });
  });
}
