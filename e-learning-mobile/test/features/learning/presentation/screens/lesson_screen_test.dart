import 'dart:async';

import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/learning/data/course_detail_repository.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/lesson_screen.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_course_detail_repository.dart';

void main() {
  testWidgets('loads lesson content, media action, and completion action', (
    tester,
  ) async {
    final harness = _buildHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(fakeLessonPart().title), findsOneWidget);
    expect(find.text('Mở trình phát video'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Đánh dấu hoàn thành'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đánh dấu hoàn thành'), findsOneWidget);
    expect(find.text('Điều hướng bài học'), findsOneWidget);
  });

  testWidgets('document lesson shows document action', (tester) async {
    final documentPart = fakeDocumentPart();
    final harness = _buildHarness(
      repository: FakeCourseDetailRepository(
        lessonResult: fakeLessonDetailResult(part: documentPart),
      ),
      lessonPartId: fakeDocumentPartId,
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text(documentPart.title), findsOneWidget);
    expect(find.text('Đọc tài liệu'), findsOneWidget);
  });

  testWidgets('shows loading state before lesson resolves', (tester) async {
    final completer = Completer<LessonDetailResult>();
    final repository = FakeCourseDetailRepository(
      onLoadLesson: (_, __) => completer.future,
    );
    final harness = _buildHarness(repository: repository);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pump();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(fakeLessonPart().title), findsNothing);

    completer.complete(fakeLessonDetailResult());
    await tester.pumpAndSettle();
  });

  testWidgets('shows error for missing lesson', (tester) async {
    const failure = AppFailure(
      type: AppFailureType.notFound,
      message: 'Not found',
    );
    final harness = _buildHarness(
      repository: FakeCourseDetailRepository(lessonError: failure),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text(learningFailureMessage(failure, fallback: 'fallback')),
      findsOneWidget,
    );
  });

  testWidgets('unsupported lesson type renders safe message', (tester) async {
    final part = fakeLessonPart(
      type: 'Interactive',
      content: null,
      playbackUrl: null,
    );
    final harness = _buildHarness(
      repository: FakeCourseDetailRepository(
        lessonResult: fakeLessonDetailResult(part: part),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text('Nội dung này chưa được hỗ trợ trên ứng dụng.'),
      findsOneWidget,
    );
  });

  testWidgets('completion success updates UI', (tester) async {
    final repository = FakeCourseDetailRepository();
    final harness = _buildHarness(repository: repository);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Đánh dấu hoàn thành'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Đánh dấu hoàn thành'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nội dung này đã được đánh dấu hoàn thành.'),
      findsOneWidget,
    );
    expect(repository.completeCallCount, 1);
  });

  testWidgets('narrow layout and large text stay stable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = _buildHarness(
      mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

_Harness _buildHarness({
  FakeCourseDetailRepository? repository,
  MediaQueryData? mediaQuery,
  String lessonPartId = fakePartId,
}) {
  final container = ProviderContainer(
    overrides: [
      courseDetailRepositoryProvider.overrideWithValue(
        repository ?? FakeCourseDetailRepository(),
      ),
    ],
  );
  final child = MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    home: Scaffold(
      body: LessonScreen(courseId: fakeCourseId, lessonPartId: lessonPartId),
    ),
  );

  return _Harness(
    container: container,
    app: UncontrolledProviderScope(
      container: container,
      child: mediaQuery == null
          ? child
          : MediaQuery(data: mediaQuery, child: child),
    ),
  );
}

class _Harness {
  const _Harness({required this.container, required this.app});

  final ProviderContainer container;
  final Widget app;
}
