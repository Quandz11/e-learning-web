import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/app/bootstrap.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/core/storage/session_storage.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/startup_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/startup_failure_screen.dart';
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:e_learning_mobile/features/profile/data/profile_api.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_home_repository.dart';

void main() {
  testWidgets('application smoke test', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
        ),
        sessionStorageProvider.overrideWithValue(_NoopStorage()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );

    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    container.dispose();
  });

  testWidgets('app with no session renders login', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
        ),
        sessionStorageProvider.overrideWithValue(_NoopStorage()),
      ],
    );
    await container.read(sessionControllerProvider.notifier).restore();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    container.dispose();
  });

  testWidgets('app with valid session renders app shell home', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
        ),
        sessionStorageProvider.overrideWithValue(
          _SeededStorage(
            AppSession(
              accessToken: 'access',
              refreshToken: 'refresh',
              expiresAt: DateTime.utc(2027, 7, 30),
            ),
          ),
        ),
      ],
    );
    await container.read(sessionControllerProvider.notifier).restore();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    container.dispose();
  });

  testWidgets('configuration failure screen test', (tester) async {
    Widget? app;

    await bootstrapAndRun(
      runner: (widget) => app = widget,
      bootstrapper: () async => throw const AppConfigException(
        'Missing API_BASE_URL',
        userMessage: 'The app configuration is incomplete.',
      ),
    );

    if (app == null) {
      fail('Bootstrap did not produce a widget');
    }

    await tester.pumpWidget(app!);
    await tester.pumpAndSettle();

    expect(find.text('The app configuration is incomplete.'), findsOneWidget);
  });

  testWidgets('startup screen renders while bootstrap is pending', (
    tester,
  ) async {
    final completer = Completer<ProviderContainer>();
    Widget? app;

    await bootstrapAndRun(
      runner: (widget) => app = widget,
      bootstrapper: () => completer.future,
    );

    await tester.pumpWidget(app!);

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);

    completer.complete(await _buildContainer(storage: _NoopStorage()));
    await tester.pumpAndSettle();

    expect(find.byType(StartupScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('unauthenticated startup reaches login once settled', (
    tester,
  ) async {
    Widget? app;

    await bootstrapAndRun(
      runner: (widget) => app = widget,
      bootstrapper: () => _buildContainer(storage: _NoopStorage()),
    );

    await tester.pumpWidget(app!);
    expect(find.byType(StartupScreen), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(StartupScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('authenticated startup reaches app home once settled', (
    tester,
  ) async {
    Widget? app;

    await bootstrapAndRun(
      runner: (widget) => app = widget,
      bootstrapper: () => _buildContainer(
        storage: _SeededStorage(
          AppSession(
            accessToken: 'access',
            refreshToken: 'refresh',
            expiresAt: DateTime.utc(2027, 7, 30),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app!);
    expect(find.byType(StartupScreen), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(StartupScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('refresh-success startup reaches app home', (tester) async {
    Widget? app;

    await bootstrapAndRun(
      runner: (widget) => app = widget,
      bootstrapper: () => _buildContainer(
        storage: _SeededStorage(
          AppSession(
            accessToken: 'expired',
            refreshToken: 'refresh',
            expiresAt: DateTime.utc(2026, 7, 29),
          ),
        ),
        dio: Dio()..httpClientAdapter = _RefreshSuccessAdapter(),
      ),
    );

    await tester.pumpWidget(app!);
    expect(find.byType(StartupScreen), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('refresh-failure startup reaches login without home flicker', (
    tester,
  ) async {
    Widget? app;

    await bootstrapAndRun(
      runner: (widget) => app = widget,
      bootstrapper: () => _buildContainer(
        storage: _SeededStorage(
          AppSession(
            accessToken: 'expired',
            refreshToken: 'refresh',
            expiresAt: DateTime.utc(2026, 7, 29),
          ),
        ),
        dio: Dio()..httpClientAdapter = _RefreshFailureAdapter(),
      ),
    );

    await tester.pumpWidget(app!);
    expect(find.byType(StartupScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('startup failure app can be rendered directly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StartupFailureScreen(message: 'Bad config')),
    );

    expect(find.text('Bad config'), findsOneWidget);
  });
}

class _NoopStorage implements SessionStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<AppSession?> read() async => null;

  @override
  Future<void> write(dynamic session) async {}
}

class _SeededStorage implements SessionStorage {
  _SeededStorage(this._session);

  AppSession? _session;

  @override
  Future<void> clear() async {}

  @override
  Future<AppSession?> read() async => _session;

  @override
  Future<void> write(dynamic session) async {
    _session = session as AppSession;
  }
}

Future<ProviderContainer> _buildContainer({
  required SessionStorage storage,
  Dio? dio,
}) async {
  final config = AppConfig(
    apiBaseUrl: Uri.parse('https://api.example.com/api'),
    flavor: AppFlavor.dev,
    paymentReturnUrl: Uri.parse('skvi://payment/result'),
    paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
  );
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sessionStorageProvider.overrideWithValue(storage),
      homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
      homeClockProvider.overrideWithValue(() => DateTime(2026, 8, 6, 8)),
      profileControllerProvider.overrideWith(
        (ref) => _BootstrapProfileController(),
      ),
      if (dio != null)
        sessionRepositoryProvider.overrideWith(
          (ref) => SessionRepository(
            storage: storage,
            config: config,
            refreshDio: dio,
          ),
        ),
    ],
  );

  await container.read(sessionControllerProvider.notifier).restore();
  return container;
}

class _BootstrapProfileController extends ProfileController {
  _BootstrapProfileController() : super(_NoopProfileRepository()) {
    state = const ProfileState();
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

class _RefreshSuccessAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"accessToken":"new-access","refreshToken":"new-refresh","expiresAt":"2027-07-31T00:00:00Z"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _RefreshFailureAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"Refresh failed"}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
      statusMessage: 'Unauthorized',
    );
  }
}
