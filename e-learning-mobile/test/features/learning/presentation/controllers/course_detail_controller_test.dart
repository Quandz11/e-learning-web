import 'dart:async';

import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/course_detail_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/course_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_course_detail_repository.dart';

void main() {
  group('CourseDetailController', () {
    test('starts with initial state', () {
      final controller = _controller(FakeCourseDetailRepository());
      addTearDown(controller.dispose);

      expect(controller.state.status, CourseDetailStatus.initial);
    });

    test('loads course detail successfully', () async {
      final repository = FakeCourseDetailRepository();
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.status, CourseDetailStatus.success);
      expect(controller.state.course?.id, fakeCourseId);
      expect(controller.state.progress, isNotNull);
    });

    test('moves to failure when primary detail load fails', () async {
      final controller = _controller(
        FakeCourseDetailRepository(
          loadError: const AppFailure(
            type: AppFailureType.notFound,
            message: 'Not found',
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.status, CourseDetailStatus.failure);
      expect(controller.state.primaryFailure?.type, AppFailureType.notFound);
    });

    test('prevents duplicate concurrent loads', () async {
      final completer = Completer<CourseDetailResult>();
      final repository = FakeCourseDetailRepository(
        onLoadDetail: (_) => completer.future,
      );
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      final firstLoad = controller.load();
      await Future<void>.delayed(Duration.zero);
      final secondLoad = controller.load();

      expect(repository.detailCallCount, 1);
      completer.complete(fakeCourseDetailResult());
      await Future.wait([firstLoad, secondLoad]);
    });
  });
}

CourseDetailController _controller(FakeCourseDetailRepository repository) {
  return CourseDetailController(courseId: fakeCourseId, repository: repository);
}
