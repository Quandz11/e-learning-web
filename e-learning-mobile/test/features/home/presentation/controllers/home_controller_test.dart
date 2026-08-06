import 'dart:async';

import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_controller.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_home_repository.dart';

void main() {
  group('HomeController', () {
    test('starts with initial state', () {
      final controller = HomeController(FakeHomeRepository());

      expect(controller.state.status, HomeStatus.initial);
      expect(controller.state.featuredCourses, isEmpty);
    });

    test('loads home content successfully', () async {
      final controller = HomeController(FakeHomeRepository());

      await controller.load();

      expect(controller.state.status, HomeStatus.success);
      expect(controller.state.featuredCourses, isNotEmpty);
      expect(controller.state.continueLearning, isNotNull);
    });

    test('captures primary failure when courses fail', () async {
      final controller = HomeController(
        FakeHomeRepository(
          error: const AppFailure(
            type: AppFailureType.server,
            message: 'Server error',
          ),
        ),
      );

      await controller.load();

      expect(controller.state.status, HomeStatus.failure);
      expect(controller.state.primaryFailure?.type, AppFailureType.server);
    });

    test('retains content during refresh failure', () async {
      final repository = FakeHomeRepository();
      final controller = HomeController(repository);
      await controller.load();

      final refreshFailureRepository = FakeHomeRepository(
        onLoad: () async => throw const AppFailure(
          type: AppFailureType.timeout,
          message: 'Timeout',
        ),
      );
      final refreshedController = HomeController(refreshFailureRepository)
        ..state = controller.state;

      await refreshedController.refresh();

      expect(refreshedController.state.status, HomeStatus.success);
      expect(refreshedController.state.featuredCourses, isNotEmpty);
      expect(
        refreshedController.state.refreshFailure?.type,
        AppFailureType.timeout,
      );
    });

    test('prevents duplicate concurrent refreshes', () async {
      final completer = Completer<void>();
      final repository = FakeHomeRepository(
        onLoad: () async {
          await completer.future;
          return fakeHomeLoadResult();
        },
      );
      final controller = HomeController(repository);

      final first = controller.load();
      final second = controller.load();
      completer.complete();
      await Future.wait([first, second]);

      expect(repository.loadCallCount, 1);
    });
  });
}
