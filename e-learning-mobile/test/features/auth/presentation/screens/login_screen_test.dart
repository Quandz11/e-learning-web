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
  testWidgets('login screen renders', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sử dụng email và mật khẩu để tiếp tục.'), findsOneWidget);
  });

  testWidgets('email and password fields render', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
  });

  testWidgets('password is obscured by default', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));

    final field = tester.widget<TextField>(
      find.byKey(const Key('login_password_field')),
    );
    expect(field.obscureText, isTrue);
  });

  testWidgets('visibility toggle works', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('login_password_field')),
    );
    expect(field.obscureText, isFalse);
  });

  testWidgets('empty submission shows validation', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
  });

  testWidgets('invalid email shows validation', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'invalid',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Email không hợp lệ.'), findsOneWidget);
  });

  testWidgets('loading state disables submit', (tester) async {
    final completer = Completer<AuthSessionResult>();
    final repository = FakeAuthRepository(onLogin: (_) => completer.future);

    await tester.pumpWidget(
      _pumpLoginScreen(const LoginScreen(), repository: repository),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('login_submit_button')),
    );
    expect(button.onPressed, isNull);

    completer.complete(
      AuthSessionResult(session: _session(), requiresTwoFactor: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('duplicate taps do not create duplicate submissions', (
    tester,
  ) async {
    final completer = Completer<AuthSessionResult>();
    final repository = FakeAuthRepository(onLogin: (_) => completer.future);

    await tester.pumpWidget(
      _pumpLoginScreen(const LoginScreen(), repository: repository),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(repository.loginCallCount, 1);

    completer.complete(
      AuthSessionResult(session: _session(), requiresTwoFactor: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('backend general error is shown', (tester) async {
    await tester.pumpWidget(
      _pumpLoginScreen(
        const LoginScreen(),
        repository: FakeAuthRepository(
          onLogin: (_) async => throw const AppFailure(
            type: AppFailureType.unauthorized,
            message: 'Invalid credentials.',
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'bad',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Invalid credentials.'), findsOneWidget);
  });

  testWidgets('backend field error is shown where practical', (tester) async {
    await tester.pumpWidget(
      _pumpLoginScreen(
        const LoginScreen(),
        repository: FakeAuthRepository(
          onLogin: (_) async => throw const AppFailure(
            type: AppFailureType.validation,
            message: 'Validation failed.',
            validationErrors: {
              'email': ['Email is invalid.'],
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Email is invalid.'), findsOneWidget);
  });

  testWidgets('successful login updates app routing', (tester) async {
    await tester.pumpWidget(
      _pumpLoginApp(
        repository: FakeAuthRepository(
          onLogin: (_) async =>
              AuthSessionResult(session: _session(), requiresTwoFactor: false),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('login two factor creates otp challenge without authenticating', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pumpLoginApp(
        repository: FakeAuthRepository(
          onLogin: (_) async => const AuthSessionResult(
            session: null,
            requiresTwoFactor: true,
            preAuthAccessToken: 'pre-auth-token',
            message: 'Enter the verification code from your authenticator app.',
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    final challenge = container.read(authOtpChallengeControllerProvider);

    expect(challenge?.type, AuthOtpChallengeType.loginTwoFactor);
    expect(challenge?.email, 'user@example.com');
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('small viewport does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('autofill and input configuration are present where testable', (
    tester,
  ) async {
    await tester.pumpWidget(_pumpLoginScreen(const LoginScreen()));

    final emailField = tester.widget<TextField>(
      find.byKey(const Key('login_email_field')),
    );
    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('login_password_field')),
    );

    expect(emailField.keyboardType, TextInputType.emailAddress);
    expect(emailField.textInputAction, TextInputAction.next);
    expect(emailField.autofillHints, contains(AutofillHints.email));
    expect(passwordField.textInputAction, TextInputAction.done);
    expect(passwordField.autofillHints, contains(AutofillHints.password));
  });
}

Widget _pumpLoginScreen(
  Widget child, {
  FakeAuthRepository? repository,
  InMemorySessionStorage? storage,
}) {
  final appConfig = _appConfig();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(appConfig),
      sessionStorageProvider.overrideWithValue(
        storage ?? InMemorySessionStorage(),
      ),
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _pumpLoginApp({
  FakeAuthRepository? repository,
  InMemorySessionStorage? storage,
}) {
  final appConfig = _appConfig();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(appConfig),
      sessionStorageProvider.overrideWithValue(
        storage ?? InMemorySessionStorage(),
      ),
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
      appRouterProvider.overrideWith((ref) {
        final sessionState = ref.watch(sessionControllerProvider);
        final deepLinks = DeepLinkConfig(appConfig);
        return GoRouter(
          initialLocation: AppRoutes.login,
          routes: [
            GoRoute(
              path: AppRoutes.welcome,
              builder: (_, __) => const Scaffold(body: Text('Welcome')),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const LoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.verifyOtp,
              builder: (_, state) => VerifyOtpScreen(
                initialChallenge: state.extra is AuthOtpChallenge
                    ? state.extra! as AuthOtpChallenge
                    : null,
              ),
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
            forgotPasswordChallenge: null,
            deepLinks: deepLinks,
            uri: state.uri,
            matchedLocation: state.matchedLocation,
            extra: state.extra,
          ),
        );
      }),
    ],
  );

  return UncontrolledProviderScope(container: container, child: const App());
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
