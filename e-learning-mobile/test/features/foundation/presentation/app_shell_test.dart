import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/features/foundation/presentation/app_shell.dart';
import 'package:e_learning_mobile/features/foundation/presentation/shell_destination_placeholder_screen.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('authenticated /app resolves to /app/home', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.appRoot);
    await tester.pumpAndSettle();

    expect(
      find.text('Home content will be implemented in a later phase.'),
      findsOneWidget,
    );
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

    expect(
      find.text('Use your account credentials to continue.'),
      findsOneWidget,
    );
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

    expect(
      find.text('Profile content will be implemented in a later phase.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shell renders bottom navigation with exactly four destinations',
    (tester) async {
      final harness = _buildHarness(
        sessionState: SessionState.authenticated(_session()),
      );
      addTearDown(harness.container.dispose);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Trang chủ'), findsWidgets);
      expect(find.text('Học tập'), findsWidgets);
      expect(find.text('Cộng đồng'), findsWidgets);
      expect(find.text('Cá nhân'), findsWidgets);
    },
  );

  testWidgets('selected destination matches current route', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    harness.router.go(AppRoutes.appCommunity);
    await tester.pumpAndSettle();

    expect(_selectedIndex(tester), 2);
  });

  testWidgets('navigation bar exposes production styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AppShell(
          currentLocation: AppRoutes.appHome,
          child: HomePlaceholderScreen(),
        ),
      ),
    );

    final barTheme = tester.widget<NavigationBarTheme>(
      find.byType(NavigationBarTheme),
    );
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(AppShell.navigationBarKey),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(barTheme.data.indicatorShape, isA<StadiumBorder>());
    expect(
      barTheme.data.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(material.elevation, greaterThan(0));
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
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(find.byIcon(Icons.groups_2_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('tapping each destination changes route', (tester) async {
    final harness = _buildHarness(
      sessionState: SessionState.authenticated(_session()),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Học tập').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Learning content will be implemented in a later phase.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cộng đồng').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Community content will be implemented in a later phase.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cá nhân').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Profile content will be implemented in a later phase.'),
      findsOneWidget,
    );
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

    await tester.tap(find.text('Học tập').last);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Trang chủ').last);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
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

    expect(safeArea.minimum.bottom, AppSpacing.md);
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
    expect(find.byType(NavigationBar), findsOneWidget);
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
    expect(find.byType(NavigationBar), findsOneWidget);
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
    expect(
      find.text('Home content will be implemented in a later phase.'),
      findsOneWidget,
    );

    harness.router.go(AppRoutes.register);
    await tester.pumpAndSettle();
    expect(
      find.text('Home content will be implemented in a later phase.'),
      findsOneWidget,
    );
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

    expect(
      find.text('Home content will be implemented in a later phase.'),
      findsOneWidget,
    );
    expect(_selectedIndex(tester), 0);
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

      await tester.tap(find.text('Học tập').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trang chủ').last);
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        find.text('Home content will be implemented in a later phase.'),
        findsOneWidget,
      );
      expect(_selectedIndex(tester), 0);
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

    expect(
      find.text('Profile content will be implemented in a later phase.'),
      findsOneWidget,
    );
    expect(_selectedIndex(tester), 3);
  });
}

int _selectedIndex(WidgetTester tester) {
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  return bar.selectedIndex;
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
    ],
  );

  return _ShellHarness(
    container: container,
    router: container.read(appRouterProvider),
    app: UncontrolledProviderScope(container: container, child: const App()),
  );
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

AppSession _session() {
  return AppSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2027, 7, 30),
  );
}
