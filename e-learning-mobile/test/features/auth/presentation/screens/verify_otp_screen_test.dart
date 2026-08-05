import 'dart:async';

import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/shell_destination_placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('otp screen renders', (tester) async {
    await tester.pumpWidget(
      _pumpOtpScreen(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
      ),
    );

    expect(find.byType(VerifyOtpScreen), findsOneWidget);
    expect(find.text('Verify your account'), findsOneWidget);
  });

  testWidgets('challenge explanation renders', (tester) async {
    await tester.pumpWidget(
      _pumpOtpScreen(
        challenge: AuthOtpChallenge.loginTwoFactor(
          email: 'user@example.com',
          preAuthAccessToken: 'pre-auth-token',
          displayMessage:
              'Enter the verification code from your authenticator app.',
        ),
      ),
    );

    expect(find.textContaining('authenticator'), findsOneWidget);
  });

  testWidgets('email is displayed safely', (tester) async {
    await tester.pumpWidget(
      _pumpOtpScreen(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
      ),
    );

    expect(find.text('us**@example.com'), findsOneWidget);
    expect(find.text('user@example.com'), findsNothing);
  });

  testWidgets('otp input configuration is present', (tester) async {
    await tester.pumpWidget(
      _pumpOtpScreen(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
      ),
    );

    final field = tester.widget<TextField>(
      find.byKey(const Key('otp_code_field')),
    );
    expect(field.keyboardType, TextInputType.number);
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
  });

  testWidgets('validation renders', (tester) async {
    await tester.pumpWidget(
      _pumpOtpScreen(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
      ),
    );

    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pump();

    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
  });

  testWidgets('loading state disables submit', (tester) async {
    final completer = Completer<AuthSessionResult>();
    await tester.pumpWidget(
      _pumpOtpApp(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        repository: FakeAuthRepository(onVerifyOtp: (_) => completer.future),
      ),
    );

    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('otp_submit_button')),
    );
    expect(button.onPressed, isNull);

    completer.complete(
      AuthSessionResult(session: _session(), requiresTwoFactor: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('backend error displays', (tester) async {
    await tester.pumpWidget(
      _pumpOtpScreen(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        repository: FakeAuthRepository(
          onVerifyOtp: (_) async => throw const AppFailure(
            type: AppFailureType.unauthorized,
            message: 'Invalid OTP.',
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pump();

    expect(find.text('Invalid OTP.'), findsOneWidget);
  });

  testWidgets('successful registration otp behavior reaches home', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pumpOtpApp(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        repository: FakeAuthRepository(
          onVerifyOtp: (_) async =>
              AuthSessionResult(session: _session(), requiresTwoFactor: false),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('successful login 2fa behavior reaches home', (tester) async {
    await tester.pumpWidget(
      _pumpOtpApp(
        challenge: AuthOtpChallenge.loginTwoFactor(
          email: 'user@example.com',
          preAuthAccessToken: 'pre-auth-token',
        ),
        repository: FakeAuthRepository(
          onVerifyLoginTwoFactor: (_, __) async =>
              AuthSessionResult(session: _session(), requiresTwoFactor: false),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('back to login action clears challenge', (tester) async {
    final container = ProviderContainer(overrides: _baseOverrides());
    container
        .read(authOtpChallengeControllerProvider.notifier)
        .setChallenge(AuthOtpChallenge.registration(email: 'user@example.com'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.verifyOtp,
            routes: [
              GoRoute(
                path: AppRoutes.login,
                builder: (_, __) => const LoginScreen(),
              ),
              GoRoute(
                path: AppRoutes.verifyOtp,
                builder: (_, __) => const VerifyOtpScreen(),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('otp_back_to_login_button')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(container.read(authOtpChallengeControllerProvider), isNull);
    container.dispose();
  });

  testWidgets('missing challenge safe handling', (tester) async {
    await tester.pumpWidget(_pumpOtpScreen());

    expect(find.textContaining('no longer available'), findsOneWidget);
  });

  testWidgets('small viewport no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _pumpOtpScreen(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Widget _pumpOtpScreen({
  AuthOtpChallenge? challenge,
  FakeAuthRepository? repository,
  InMemorySessionStorage? storage,
}) {
  final container = ProviderContainer(
    overrides: [
      ..._baseOverrides(storage: storage),
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
    ],
  );
  if (challenge != null) {
    container
        .read(authOtpChallengeControllerProvider.notifier)
        .setChallenge(challenge);
  }

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: VerifyOtpScreen())),
  );
}

Widget _pumpOtpApp({
  required AuthOtpChallenge challenge,
  FakeAuthRepository? repository,
  InMemorySessionStorage? storage,
}) {
  final appConfig = _appConfig();
  final container = ProviderContainer(
    overrides: [
      ..._baseOverrides(storage: storage),
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
      appRouterProvider.overrideWith((ref) {
        final sessionState = ref.watch(sessionControllerProvider);
        final deepLinks = DeepLinkConfig(appConfig);
        return GoRouter(
          initialLocation: AppRoutes.verifyOtp,
          routes: [
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const LoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.verifyOtp,
              builder: (_, __) => const VerifyOtpScreen(),
            ),
            GoRoute(
              path: AppRoutes.appHome,
              builder: (_, __) => const HomePlaceholderScreen(),
            ),
            GoRoute(
              path: AppRoutes.paymentReturn,
              builder: (_, __) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: AppRoutes.paymentCancel,
              builder: (_, __) => const SizedBox.shrink(),
            ),
          ],
          redirect: (_, state) => appRedirect(
            sessionState: sessionState,
            otpChallenge: ref.watch(authOtpChallengeControllerProvider),
            deepLinks: deepLinks,
            uri: state.uri,
            matchedLocation: state.matchedLocation,
          ),
        );
      }),
    ],
  );
  container
      .read(authOtpChallengeControllerProvider.notifier)
      .setChallenge(challenge);

  return UncontrolledProviderScope(container: container, child: const App());
}

List<Override> _baseOverrides({InMemorySessionStorage? storage}) {
  return [
    appConfigProvider.overrideWithValue(_appConfig()),
    sessionStorageProvider.overrideWithValue(
      storage ?? InMemorySessionStorage(),
    ),
  ];
}

AppConfig _appConfig() {
  return AppConfig(
    apiBaseUrl: Uri.parse('https://api.example.com/api'),
    flavor: AppFlavor.dev,
    paymentReturnUrl: Uri.parse('skvi://payment/result'),
    paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
  );
}

AppSession _session() {
  return AppSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2026, 7, 30),
  );
}
