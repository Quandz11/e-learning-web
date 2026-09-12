import 'package:dio/dio.dart';
import 'dart:async';

import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/features/foundation/presentation/app_shell.dart';
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/learning/data/course_detail_repository.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/course_detail_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/document_reader_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/lesson_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/media_player_screen.dart';
import 'package:e_learning_mobile/features/learning/presentation/widgets/document_reader_panel.dart';
import 'package:e_learning_mobile/features/learning/presentation/widgets/media_player_panel.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/profile_api.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_course_detail_repository.dart';
import '../../../../helpers/fake_home_repository.dart';
import '../../../../helpers/fake_learning_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('loads course detail with progress and lesson list', (
    tester,
  ) async {
    final harness = _buildScreenHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(CourseDetailScreen), findsOneWidget);
    expect(find.text(fakeDetailCourse().title), findsOneWidget);
    expect(find.text(fakeDetailCourse().instructorName!), findsOneWidget);
    expect(find.textContaining('bài học'), findsWidgets);
    expect(find.text(fakeLesson().title), findsOneWidget);
    expect(find.text(fakeLessonPart().title), findsOneWidget);
  });

  testWidgets('renders loading state before course resolves', (tester) async {
    final completer = Completer<CourseDetailResult>();
    final repository = FakeCourseDetailRepository(
      onLoadDetail: (_) => completer.future,
    );
    final harness = _buildScreenHarness(repository: repository);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pump();

    expect(find.byType(CourseDetailScreen), findsOneWidget);
    expect(find.text('Nội dung khóa học'), findsNothing);

    completer.complete(fakeCourseDetailResult());
    await tester.pumpAndSettle();
  });

  testWidgets('renders error and retry for primary failure', (tester) async {
    final repository = FakeCourseDetailRepository(
      loadError: const AppFailure(
        type: AppFailureType.notFound,
        message: 'Not found',
      ),
    );
    final harness = _buildScreenHarness(repository: repository);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text(
        learningFailureMessage(
          repository.loadError!,
          fallback: 'Không thể tải khóa học lúc này.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('omits missing optional fields and shows image fallback', (
    tester,
  ) async {
    final course = fakeDetailCourse(lessons: const []);
    final repository = FakeCourseDetailRepository(
      detailResult: CourseDetailResult(course: course),
    );
    final harness = _buildScreenHarness(repository: repository);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.text('Khóa học chưa có nội dung hiển thị.'), findsOneWidget);
  });

  testWidgets('navigates to lesson from accessible lesson part', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = _buildAppHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router!.go(AppRoutes.appLearning);
    await tester.pumpAndSettle();

    final courseTitle = find.text(fakeDetailCourse().title).last;
    await tester.scrollUntilVisible(
      courseTitle,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final courseCard = find.ancestor(
      of: courseTitle,
      matching: find.byType(AppCard),
    );
    await tester.tap(courseCard.first);
    await tester.pumpAndSettle();
    expect(find.byType(CourseDetailScreen), findsOneWidget);

    harness.router!.push(
      AppRoutes.lessonPath(courseId: fakeCourseId, lessonPartId: fakePartId),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
  });

  testWidgets('lesson child routes resolve media player and document reader', (
    tester,
  ) async {
    final harness = _buildAppHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router!.go(
      AppRoutes.mediaPlayerPath(
        courseId: fakeCourseId,
        lessonPartId: fakePartId,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MediaPlayerScreen), findsOneWidget);
    expect(find.text('Fake player: ${fakeLessonPart().title}'), findsOneWidget);
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);

    harness.router!.go(
      AppRoutes.documentReaderPath(
        courseId: fakeCourseId,
        lessonPartId: fakeDocumentPartId,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DocumentReaderScreen), findsOneWidget);
    expect(
      find.text('Fake reader: ${fakeDocumentPart().documentFileName}'),
      findsOneWidget,
    );
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
  });
}

_Harness _buildScreenHarness({FakeCourseDetailRepository? repository}) {
  final container = ProviderContainer(
    overrides: [
      courseDetailRepositoryProvider.overrideWithValue(
        repository ?? FakeCourseDetailRepository(),
      ),
    ],
  );

  return _Harness(
    container: container,
    router: null,
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(body: CourseDetailScreen(courseId: fakeCourseId)),
      ),
    ),
  );
}

_Harness _buildAppHarness() {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(_config()),
      sessionStorageProvider.overrideWithValue(InMemorySessionStorage()),
      sessionControllerProvider.overrideWith(
        (ref) => _TestSessionController(
          SessionState.authenticated(
            AppSession(
              accessToken: 'access',
              refreshToken: 'refresh',
              expiresAt: DateTime.utc(2027),
            ),
          ),
        ),
      ),
      learningRepositoryProvider.overrideWithValue(
        FakeLearningRepository(
          result: fakeLearningLoadResult(
            courses: [
              LearningCourse(
                id: fakeCourseId,
                title: 'Nhập môn nhịn ăn chữa lành',
                price: 0,
                isFree: true,
                isPublished: true,
                createdAt: DateTime.utc(2026),
                learningOutcomes: const [],
              ),
            ],
          ),
        ),
      ),
      courseDetailRepositoryProvider.overrideWithValue(
        FakeCourseDetailRepository(
          onLoadLesson: (_, partId) async {
            final part = partId == fakeDocumentPartId
                ? fakeDocumentPart()
                : fakeLessonPart(id: partId);
            return fakeLessonDetailResult(part: part);
          },
        ),
      ),
      learningMediaPlayerBuilderProvider.overrideWithValue(
        ({
          required url,
          required title,
          required duration,
          embedUrl,
          videoId,
        }) => Text('Fake player: $title'),
      ),
      documentReaderBuilderProvider.overrideWithValue(
        ({
          required url,
          required title,
          controller,
          onDocumentLoaded,
          onPageChanged,
        }) => Text('Fake reader: $title'),
      ),
      homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
      profileControllerProvider.overrideWith((ref) => _TestProfileController()),
    ],
  );
  final router = container.read(appRouterProvider);
  return _Harness(
    container: container,
    router: router,
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
      ),
    ),
  );
}

class _Harness {
  const _Harness({
    required this.container,
    required this.router,
    required this.app,
  });

  final ProviderContainer container;
  final GoRouter? router;
  final Widget app;
}

AppConfig _config() {
  return AppConfig(
    apiBaseUrl: Uri.parse('https://api.example.com/api'),
    flavor: AppFlavor.dev,
    paymentReturnUrl: Uri.parse('skvi://payment/result'),
    paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
  );
}

class _TestSessionController extends SessionController {
  _TestSessionController(SessionState initialState)
    : super(
        SessionRepository(storage: InMemorySessionStorage(), config: _config()),
      ) {
    state = initialState;
  }
}

class _TestProfileController extends ProfileController {
  _TestProfileController() : super(_NoopProfileRepository()) {
    state = ProfileState(
      status: ProfileStatus.success,
      profile: Profile(
        id: 'student-1',
        email: 'student@example.com',
        fullName: 'Người học',
        phone: '0912345678',
        role: 'Student',
        status: 'Active',
        avatarUrl: null,
        isEmailVerified: true,
        isPhoneVerified: true,
        isTwoFactorEnabled: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
  }
}

class _NoopProfileRepository extends ProfileRepository {
  _NoopProfileRepository() : super(api: _NoopProfileApi());
}

class _NoopProfileApi extends ProfileApi {
  _NoopProfileApi()
    : super(apiClient: ApiClient(Dio()), errorMapper: const DioErrorMapper());
}
