import 'dart:async';

import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/shell_destination_placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('registration screen renders', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Create account'), findsAtLeastNWidgets(1));
  });

  testWidgets('all confirmed fields render', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    expect(find.byKey(const Key('register_full_name_field')), findsOneWidget);
    expect(find.byKey(const Key('register_email_field')), findsOneWidget);
    expect(find.byKey(const Key('register_password_field')), findsOneWidget);
    expect(
      find.byKey(const Key('register_confirm_password_field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
    expect(
      find.byKey(const Key('register_referral_code_field')),
      findsOneWidget,
    );
  });

  testWidgets('optional fields are marked appropriately', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    expect(find.text('Phone (optional)'), findsOneWidget);
    expect(find.text('Referral code (optional)'), findsOneWidget);
  });

  testWidgets('password fields are obscured', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('register_password_field')),
    );
    final confirmField = tester.widget<TextField>(
      find.byKey(const Key('register_confirm_password_field')),
    );

    expect(passwordField.obscureText, isTrue);
    expect(confirmField.obscureText, isTrue);
  });

  testWidgets('visibility controls work', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    await tester.tap(find.byTooltip('Show confirm password'));
    await tester.pump();

    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('register_password_field')),
    );
    final confirmField = tester.widget<TextField>(
      find.byKey(const Key('register_confirm_password_field')),
    );

    expect(passwordField.obscureText, isFalse);
    expect(confirmField.obscureText, isFalse);
  });

  testWidgets('empty submit shows validation', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pump();

    expect(find.text('Full name is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Confirm your password.'), findsOneWidget);
  });

  testWidgets('confirm-password mismatch shows validation', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    await tester.enterText(
      find.byKey(const Key('register_full_name_field')),
      'User',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'secret',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'other',
    );
    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('loading disables submit', (tester) async {
    final completer = Completer<String>();
    final repository = FakeAuthRepository(onRegister: (_) => completer.future);

    await tester.pumpWidget(
      _pumpRegisterScreen(const RegisterScreen(), repository: repository),
    );

    await _fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('register_submit_button')),
    );
    expect(button.onPressed, isNull);

    completer.complete('Registration successful. Please verify your email.');
    await tester.pumpAndSettle();
  });

  testWidgets('duplicate taps do not duplicate submission', (tester) async {
    final completer = Completer<String>();
    final repository = FakeAuthRepository(onRegister: (_) => completer.future);

    await tester.pumpWidget(
      _pumpRegisterScreen(const RegisterScreen(), repository: repository),
    );

    await _fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pump();

    expect(repository.registerCallCount, 1);

    completer.complete('Registration successful. Please verify your email.');
    await tester.pumpAndSettle();
  });

  testWidgets('backend field error displays', (tester) async {
    await tester.pumpWidget(
      _pumpRegisterScreen(
        const RegisterScreen(),
        repository: FakeAuthRepository(
          onRegister: (_) async => throw const AppFailure(
            type: AppFailureType.validation,
            message: 'Validation failed.',
            validationErrors: {
              'email': ['Email is invalid.'],
            },
          ),
        ),
      ),
    );

    await _fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pump();

    expect(find.text('Email is invalid.'), findsOneWidget);
  });

  testWidgets('general backend error displays', (tester) async {
    await tester.pumpWidget(
      _pumpRegisterScreen(
        const RegisterScreen(),
        repository: FakeAuthRepository(
          onRegister: (_) async => throw const AppFailure(
            type: AppFailureType.business,
            message: 'Email is already registered.',
          ),
        ),
      ),
    );

    await _fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pump();

    expect(find.text('Email is already registered.'), findsOneWidget);
  });

  testWidgets('registration success creates otp challenge', (tester) async {
    await tester.pumpWidget(
      _pumpRegisterScreen(
        const RegisterScreen(),
        repository: FakeAuthRepository(
          onRegister: (_) async =>
              'Registration successful. Please verify your email.',
        ),
      ),
    );

    await _fillValidForm(tester);
    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VerifyOtpScreen)),
    );
    final challenge = container.read(authOtpChallengeControllerProvider);

    expect(challenge?.type, AuthOtpChallengeType.registration);
    expect(challenge?.email, 'user@example.com');
    expect(find.byType(VerifyOtpScreen), findsOneWidget);
    expect(find.text('Verify your account'), findsOneWidget);
  });

  testWidgets('login navigation works', (tester) async {
    await tester.pumpWidget(_pumpRegisterApp());

    await tester.tap(find.byKey(const Key('login_to_register_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('register_to_login_button')),
    );
    await tester.tap(find.byKey(const Key('register_to_login_button')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('small viewport does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('input configuration is present where testable', (tester) async {
    await tester.pumpWidget(_pumpRegisterScreen(const RegisterScreen()));

    final emailField = tester.widget<TextField>(
      find.byKey(const Key('register_email_field')),
    );
    final phoneField = tester.widget<TextField>(
      find.byKey(const Key('register_phone_field')),
    );

    expect(emailField.keyboardType, TextInputType.emailAddress);
    expect(emailField.autofillHints, contains(AutofillHints.email));
    expect(phoneField.keyboardType, TextInputType.phone);
  });
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('register_full_name_field')),
    'User',
  );
  await tester.enterText(
    find.byKey(const Key('register_email_field')),
    'user@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('register_password_field')),
    'secret',
  );
  await tester.enterText(
    find.byKey(const Key('register_confirm_password_field')),
    'secret',
  );
}

Widget _pumpRegisterScreen(
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
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: AppRoutes.register,
        routes: [
          GoRoute(path: AppRoutes.register, builder: (_, __) => child),
          GoRoute(
            path: AppRoutes.verifyOtp,
            builder: (_, state) => VerifyOtpScreen(
              initialChallenge: otpChallengeFromRouteState(state),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _pumpRegisterApp({
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
              path: AppRoutes.register,
              builder: (_, __) => const RegisterScreen(),
            ),
            GoRoute(
              path: AppRoutes.verifyOtp,
              builder: (_, state) => VerifyOtpScreen(
                initialChallenge: otpChallengeFromRouteState(state),
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
