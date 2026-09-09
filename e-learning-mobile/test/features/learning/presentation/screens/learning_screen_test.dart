import 'dart:async';

import 'package:dio/dio.dart';
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
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:e_learning_mobile/features/learning/presentation/screens/learning_screen.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/profile_api.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_home_repository.dart';
import '../../../../helpers/fake_learning_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('shows loading state before content resolves', (tester) async {
    final completer = Completer<LearningLoadResult>();
    final harness = _buildScreenHarness(
      repository: FakeLearningRepository(onLoad: () => completer.future),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pump();

    expect(find.byType(LearningScreen), findsOneWidget);
    expect(find.text('Khóa học hiện có'), findsNothing);

    completer.complete(fakeLearningLoadResult());
    await tester.pumpAndSettle();
  });

  testWidgets('shows heading, my learning, categories, and catalog', (
    tester,
  ) async {
    final harness = _buildScreenHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Học tập'), findsAtLeastNWidgets(1));
    expect(find.text('Khóa học của tôi'), findsOneWidget);
    expect(find.text('Danh mục'), findsOneWidget);
    expect(find.text('Khóa học hiện có'), findsOneWidget);
    expect(find.text('Nhập môn nhịn ăn chữa lành'), findsWidgets);
    expect(find.text('Dinh dưỡng'), findsOneWidget);
  });

  testWidgets('enrollment empty state is not fatal', (tester) async {
    final harness = _buildScreenHarness(
      repository: FakeLearningRepository(
        result: fakeLearningLoadResult(enrollments: const []),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bạn chưa đăng ký khóa học nào. Khám phá các khóa học phù hợp với bạn bên dưới.',
      ),
      findsOneWidget,
    );
    expect(find.text('Khóa học hiện có'), findsOneWidget);
  });

  testWidgets('course catalog empty state is shown', (tester) async {
    final harness = _buildScreenHarness(
      repository: FakeLearningRepository(
        result: fakeLearningLoadResult(courses: const []),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa có khóa học phù hợp. Vui lòng quay lại sau.'),
      findsOneWidget,
    );
  });

  testWidgets('course card renders confirmed fields and image fallback', (
    tester,
  ) async {
    final harness = _buildScreenHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Giảng viên An'), findsOneWidget);
    expect(find.text('Miễn phí'), findsOneWidget);
    expect(find.text('Khóa học trả phí'), findsOneWidget);
    expect(find.text('Thời hạn truy cập 30 ngày'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
  });

  testWidgets('long Vietnamese course title does not overflow', (tester) async {
    final harness = _buildScreenHarness(
      repository: FakeLearningRepository(
        result: fakeLearningLoadResult(
          courses: [
            LearningCourse(
              id: 'course-long',
              title:
                  'Khóa học thực hành nhịn ăn chữa lành chuyên sâu cho người mới bắt đầu trong nhịp sống hiện đại',
              price: 0,
              isFree: true,
              isPublished: true,
              createdAt: DateTime.utc(2026),
              learningOutcomes: const [],
            ),
          ],
        ),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('optional enrollment failure keeps catalog visible', (
    tester,
  ) async {
    final harness = _buildScreenHarness(
      repository: FakeLearningRepository(
        result: fakeLearningLoadResult(
          enrollments: const [],
          enrollmentIssue: const LearningSectionIssue(
            failure: AppFailure(
              type: AppFailureType.server,
              message: 'Enrollment failure',
            ),
          ),
        ),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text('Máy chủ đang bận. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
    expect(find.text('Khóa học hiện có'), findsOneWidget);
  });

  testWidgets('category section is omitted when empty without failure', (
    tester,
  ) async {
    final harness = _buildScreenHarness(
      repository: FakeLearningRepository(
        result: fakeLearningLoadResult(categories: const []),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Danh mục'), findsNothing);
    expect(find.text('Khóa học hiện có'), findsOneWidget);
  });

  testWidgets('category failure is isolated', (tester) async {
    final harness = _buildScreenHarness(
      repository: FakeLearningRepository(
        result: fakeLearningLoadResult(
          categories: const [],
          categoryIssue: const LearningSectionIssue(
            failure: AppFailure(
              type: AppFailureType.timeout,
              message: 'Timeout',
            ),
          ),
        ),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text('Máy chủ phản hồi quá chậm. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Khóa học hiện có'), findsOneWidget);
  });

  testWidgets('primary course failure renders retry state', (tester) async {
    final repository = FakeLearningRepository(
      error: const AppFailure(
        type: AppFailureType.connectionFailure,
        message: 'Connection failed',
      ),
    );
    final harness = _buildScreenHarness(repository: repository);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Không có kết nối mạng ổn định.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('pull to refresh preserves rendered content', (tester) async {
    final repository = FakeLearningRepository();
    final harness = _buildScreenHarness(repository: repository);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.loadCallCount, greaterThanOrEqualTo(2));
    expect(find.text('Khóa học hiện có'), findsOneWidget);
  });

  testWidgets('unsupported search filter and checkout controls are absent', (
    tester,
  ) async {
    final harness = _buildScreenHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsNothing);
    expect(find.text('Thanh toán'), findsNothing);
    expect(find.text('Đăng ký khóa học'), findsNothing);
    expect(find.text('Bắt đầu học'), findsNothing);
  });

  testWidgets('narrow width and large text stay stable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = _buildScreenHarness(
      mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode renders learning screen', (tester) async {
    final harness = _buildScreenHarness(themeMode: ThemeMode.dark);
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(LearningScreen), findsOneWidget);
    expect(find.text('Khóa học hiện có'), findsOneWidget);
  });

  testWidgets('/app/learning keeps learning tab selected', (tester) async {
    final harness = _buildAppHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router!.go(AppRoutes.appLearning);
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
    expect(find.byType(LearningScreen), findsOneWidget);
  });
}

_LearningHarness _buildScreenHarness({
  FakeLearningRepository? repository,
  ThemeMode themeMode = ThemeMode.light,
  MediaQueryData? mediaQuery,
}) {
  final container = ProviderContainer(
    overrides: [
      learningRepositoryProvider.overrideWithValue(
        repository ?? FakeLearningRepository(),
      ),
    ],
  );

  final child = MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    home: const Scaffold(body: LearningScreen()),
  );

  return _LearningHarness(
    container: container,
    router: null,
    app: UncontrolledProviderScope(
      container: container,
      child: mediaQuery == null
          ? child
          : MediaQuery(data: mediaQuery, child: child),
    ),
  );
}

_LearningHarness _buildAppHarness() {
  final appConfig = AppConfig(
    apiBaseUrl: Uri.parse('https://api.example.com/api'),
    flavor: AppFlavor.dev,
    paymentReturnUrl: Uri.parse('skvi://payment/result'),
    paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
  );
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(appConfig),
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
      learningRepositoryProvider.overrideWithValue(FakeLearningRepository()),
      homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
      profileControllerProvider.overrideWith((ref) => _TestProfileController()),
    ],
  );
  final router = container.read(appRouterProvider);

  return _LearningHarness(
    container: container,
    router: router,
    app: UncontrolledProviderScope(
      container: container,
      child: const AppRoot(),
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return MaterialApp.router(
      routerConfig: container.read(appRouterProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }
}

class _LearningHarness {
  const _LearningHarness({
    required this.container,
    required this.router,
    required this.app,
  });

  final ProviderContainer container;
  final GoRouter? router;
  final Widget app;
}

class _TestSessionController extends SessionController {
  _TestSessionController(SessionState initialState)
    : super(
        SessionRepository(
          storage: InMemorySessionStorage(),
          config: AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
        ),
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
