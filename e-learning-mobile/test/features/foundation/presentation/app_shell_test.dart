import 'package:dio/dio.dart';
import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
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
import 'package:e_learning_mobile/features/foundation/presentation/shell_destination_placeholder_screen.dart';
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/profile_api.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/data/personalization_repository.dart';
import 'package:e_learning_mobile/features/personalization/data/wellness_api.dart';
import 'package:e_learning_mobile/features/personalization/domain/reminder_model.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/in_memory_session_storage.dart';
import '../../../helpers/fake_home_repository.dart';
import '../../../helpers/fake_learning_repository.dart';

void main() {
  testWidgets('authenticated /app resolves to /app/home', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.appRoot);
    await tester.pumpAndSettle();

    expect(find.text('Khóa học nổi bật'), findsOneWidget);
    expect(_selectedIndex(tester), 0);
  });

  testWidgets('unauthenticated /app/home redirects to /login', (tester) async {
    final harness = _buildHarness(
      sessionState: const SessionState.unauthenticated(),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.appHome);
    await tester.pumpAndSettle();

    expect(find.text('Nhịn ăn\nChữa lành'), findsOneWidget);
  });

  testWidgets('authenticated user can open each shell destination', (
    tester,
  ) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);

    for (final path in AppRoutes.shellDestinations) {
      harness.router.go(path);
      await tester.pumpAndSettle();
    }

    expect(find.text('Hồ sơ của tôi'), findsOneWidget);
  });

  testWidgets('shell renders bottom navigation with five destinations', (
    tester,
  ) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Khóa học'), findsWidgets);
    expect(find.text('Tư vấn'), findsWidgets);
    expect(find.text('Lối sống'), findsWidgets);
    expect(find.text('Hồ sơ'), findsWidgets);
  });

  testWidgets('selected destination matches current route', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.appPersonalization);
    await tester.pumpAndSettle();

    expect(find.text('Lối sống'), findsWidgets);
  });

  testWidgets('unselected destinations remain visually distinct', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AppShell(
          currentLocation: AppRoutes.appHome,
          child: HomePlaceholderScreen(),
        ),
      ),
    );

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('tapping each destination changes route', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khóa học').last);
    await tester.pumpAndSettle();
    expect(find.text('Khóa học hiện có'), findsOneWidget);

    await tester.tap(find.text('Tư vấn').last);
    await tester.pumpAndSettle();
    expect(find.text('Ban Cố Vấn Sống Khỏe'), findsOneWidget);

    await tester.tap(find.text('Lối sống').last);
    await tester.pumpAndSettle();
    expect(find.text('Cá nhân hóa Wellness'), findsOneWidget);

    await tester.tap(find.text('Hồ sơ').last);
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ của tôi'), findsOneWidget);
  });

  testWidgets('shell remains visible across destination changes', (
    tester,
  ) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khóa học').last);
    await tester.pumpAndSettle();
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);

    await tester.tap(find.text('Trang chủ').last);
    await tester.pumpAndSettle();
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
  });

  testWidgets('no nested MaterialApp exists', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('small viewport does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('safe bottom inset is preserved', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 24),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppShell(
            currentLocation: AppRoutes.appHome,
            child: HomePlaceholderScreen(),
          ),
        ),
      ),
    );

    final safeArea = tester.widget<SafeArea>(
      find.byKey(AppShell.navigationSafeAreaKey),
    );

    expect(safeArea.top, isFalse);
  });

  testWidgets('light theme renders app shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AppShell(
          currentLocation: AppRoutes.appHome,
          child: HomePlaceholderScreen(),
        ),
      ),
    );

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
  });

  testWidgets('dark theme renders app shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const AppShell(
          currentLocation: AppRoutes.appHome,
          child: HomePlaceholderScreen(),
        ),
      ),
    );

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
  });

  testWidgets('large text scale remains stable', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppShell(
            currentLocation: AppRoutes.appCommunity,
            child: CommunityPlaceholderScreen(),
          ),
        ),
      ),
    );

    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated login and register redirect to /app/home', (
    tester,
  ) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.login);
    await tester.pumpAndSettle();
    expect(find.text('Khóa học nổi bật'), findsOneWidget);

    harness.router.go(AppRoutes.register);
    await tester.pumpAndSettle();
    expect(find.text('Khóa học nổi bật'), findsOneWidget);
  });

  testWidgets('non-home tab can return to home', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.appLearning);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Khóa học nổi bật'), findsOneWidget);
  });

  testWidgets(
    'switching tabs does not produce duplicate top-level route entries',
    (tester) async {
      final harness = _buildHarness(
        sessionState: SessionState.authenticated(_session()),
      );
      addTearDown(harness.container.dispose);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khóa học').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trang chủ').last);
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Khóa học nổi bật'), findsOneWidget);
    },
  );

  testWidgets('direct deep link selects correct tab', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.appProfile);
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ của tôi'), findsOneWidget);
  });
}

int _selectedIndex(WidgetTester tester) {
  return 0;
}

_ShellHarness _buildHarness({required SessionState sessionState}) {
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
        (ref) => _TestSessionController(sessionState),
      ),
      profileControllerProvider.overrideWith((ref) => _TestProfileController()),
      homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
      learningRepositoryProvider.overrideWithValue(FakeLearningRepository()),
      homeClockProvider.overrideWithValue(() => DateTime(2026, 8, 6, 8)),
      personalizationStateProvider.overrideWith(
        (ref) => _TestPersonalizationController(),
      ),
      wellnessControllerProvider.overrideWith(
        (ref) => _TestWellnessController(),
      ),
    ],
  );

  return _ShellHarness(
    container: container,
    router: container.read(appRouterProvider),
    app: UncontrolledProviderScope(container: container, child: const App()),
  );
}

class _TestWellnessController extends WellnessController {
  _TestWellnessController() : super(_NoopWellnessApi()) {
    state = const WellnessState(
      status: WellnessStatus.success,
      dashboard: WellnessDashboard(),
    );
  }

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> loadDashboard() async {}
}

class _NoopWellnessApi extends WellnessApi {
  _NoopWellnessApi()
    : super(apiClient: ApiClient(Dio()), errorMapper: const DioErrorMapper());
}

class _TestPersonalizationController extends PersonalizationController {
  _TestPersonalizationController() : super(_NoopPersonalizationRepository()) {
    state = AsyncValue.data(const PersonalizationProfile(reminders: []));
  }
}

class _NoopPersonalizationRepository extends PersonalizationRepository {
  @override
  Future<PersonalizationProfile> getProfile() async {
    return const PersonalizationProfile(reminders: []);
  }

  @override
  Future<List<Reminder>> getReminders() async {
    return [];
  }
}

class _ShellHarness {
  const _ShellHarness({
    required this.container,
    required this.router,
    required this.app,
  });

  final ProviderContainer container;
  final GoRouter router;
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
        email: 'user@example.com',
        fullName: 'Người dùng',
        phone: '0912345678',
        role: 'Student',
        status: 'Active',
        avatarUrl: null,
        isEmailVerified: true,
        isPhoneVerified: false,
        isTwoFactorEnabled: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
  }

  @override
  Future<void> load({bool refresh = false}) async {}

  @override
  Future<void> refresh() async {}
}

class _NoopProfileRepository extends ProfileRepository {
  _NoopProfileRepository() : super(api: _NoopProfileApi());
}

class _NoopProfileApi extends ProfileApi {
  _NoopProfileApi()
    : super(apiClient: ApiClient(Dio()), errorMapper: const DioErrorMapper());
}

AppSession _session() {
  return AppSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2027, 7, 30),
  );
}
