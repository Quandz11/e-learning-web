import 'dart:async';

import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/lesson_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_course_detail_repository.dart';

void main() {
  group('LessonController', () {
    test('loads lesson content successfully', () async {
      final controller = _controller(FakeCourseDetailRepository());
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.status, LessonStatus.success);
      expect(controller.state.detail?.part.id, fakePartId);
    });

    test('moves to failure when lesson is not found', () async {
      final controller = _controller(
        FakeCourseDetailRepository(
          lessonError: const AppFailure(
            type: AppFailureType.notFound,
            message: 'Not found',
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.status, LessonStatus.failure);
      expect(controller.state.primaryFailure?.type, AppFailureType.notFound);
    });

    test('successful completion updates backend-confirmed state', () async {
      final repository = FakeCourseDetailRepository();
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.load();
      await controller.markComplete();

      expect(controller.state.detail?.partProgress?.isCompleted, isTrue);
      expect(repository.completeCallCount, 1);
    });

    test('completion failure keeps current lesson content', () async {
      final controller = _controller(
        FakeCourseDetailRepository(
          completeError: const AppFailure(
            type: AppFailureType.server,
            message: 'Server',
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.markComplete();

      expect(controller.state.detail?.part.id, fakePartId);
      expect(controller.state.completionFailure?.type, AppFailureType.server);
    });

    test('prevents duplicate completion actions', () async {
      final completer = Completer<LessonDetailResult>();
      final repository = FakeCourseDetailRepository(
        onComplete: (_, __) => completer.future,
      );
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.load();
      final firstCompletion = controller.markComplete();
      await Future<void>.delayed(Duration.zero);
      final secondCompletion = controller.markComplete();

      expect(repository.completeCallCount, 1);
      completer.complete(fakeLessonDetailResult(completed: true));
      await Future.wait([firstCompletion, secondCompletion]);
    });
  });
}

LessonController _controller(FakeCourseDetailRepository repository) {
  return LessonController(
    courseId: fakeCourseId,
    lessonPartId: fakePartId,
    repository: repository,
  );
}
