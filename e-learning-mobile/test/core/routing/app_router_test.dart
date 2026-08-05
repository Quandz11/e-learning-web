import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deepLinks = DeepLinkConfig(
    AppConfig(
      apiBaseUrl: Uri.parse('https://api.example.com/api'),
      flavor: AppFlavor.dev,
      paymentReturnUrl: Uri.parse('skvi://payment/result'),
      paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
    ),
  );

  test('unauthenticated user cannot enter app root route', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/app'),
      matchedLocation: AppRoutes.appRoot,
    );

    expect(redirect, contains(AppRoutes.login));
  });

  test('authenticated user can enter app root route', () {
    final redirect = appRedirect(
      sessionState: SessionState.authenticated(
        AppSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2026, 7, 30),
        ),
      ),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/app'),
      matchedLocation: AppRoutes.appRoot,
    );

    expect(redirect, isNull);
  });

  test('router initial location points at protected root', () {
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
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.appRoot);
  });

  test('unauthenticated user cannot enter shell destination route', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse(AppRoutes.appLearning),
      matchedLocation: AppRoutes.appLearning,
    );

    expect(redirect, contains(AppRoutes.login));
  });

  test('restoring session does not create redirect loop', () {
    final redirect = appRedirect(
      sessionState: const SessionState.restoring(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/welcome'),
      matchedLocation: AppRoutes.welcome,
    );

    expect(redirect, isNull);
  });

  test('authenticated user behavior on public route is deterministic', () {
    final redirect = appRedirect(
      sessionState: SessionState.authenticated(
        AppSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2026, 7, 30),
        ),
      ),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/welcome'),
      matchedLocation: AppRoutes.welcome,
    );

    expect(redirect, AppRoutes.appHome);
  });

  test('unauthenticated user can open login', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/login'),
      matchedLocation: AppRoutes.login,
    );

    expect(redirect, isNull);
  });

  test('unauthenticated user can open register', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/register'),
      matchedLocation: AppRoutes.register,
    );

    expect(redirect, isNull);
  });

  test('authenticated user is redirected away from login', () {
    final redirect = appRedirect(
      sessionState: SessionState.authenticated(
        AppSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2026, 7, 30),
        ),
      ),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/login'),
      matchedLocation: AppRoutes.login,
    );

    expect(redirect, AppRoutes.appHome);
  });

  test('authenticated user is redirected away from register', () {
    final redirect = appRedirect(
      sessionState: SessionState.authenticated(
        AppSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2026, 7, 30),
        ),
      ),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/register'),
      matchedLocation: AppRoutes.register,
    );

    expect(redirect, AppRoutes.appHome);
  });

  test('payment callback routes resolve', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('skvi://payment/result?orderCode=123'),
      matchedLocation: '/unknown',
    );

    expect(redirect, contains(AppRoutes.paymentReturn));
  });

  test('unknown route resolves to no redirect', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/missing'),
      matchedLocation: '/missing',
    );

    expect(redirect, isNull);
  });

  test('debug component route resolves to no redirect', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse(AppRoutes.devComponents),
      matchedLocation: AppRoutes.devComponents,
    );

    expect(redirect, isNull);
  });

  test('missing otp challenge redirects to login', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse(AppRoutes.verifyOtp),
      matchedLocation: AppRoutes.verifyOtp,
    );

    expect(redirect, AppRoutes.login);
  });

  test('valid registration otp challenge allows route', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: AuthOtpChallenge.registration(email: 'user@example.com'),
      deepLinks: deepLinks,
      uri: Uri.parse(AppRoutes.verifyOtp),
      matchedLocation: AppRoutes.verifyOtp,
    );

    expect(redirect, isNull);
  });

  test('valid otp challenge passed through route extra allows route', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse(AppRoutes.verifyOtp),
      matchedLocation: AppRoutes.verifyOtp,
      extra: AuthOtpChallenge.registration(email: 'user@example.com'),
    );

    expect(redirect, isNull);
  });

  test('valid registration query handoff allows verify otp route', () {
    final redirect = appRedirect(
      sessionState: const SessionState.unauthenticated(),
      otpChallenge: null,
      deepLinks: deepLinks,
      uri: Uri.parse('/verify-otp?type=registration&email=user@example.com'),
      matchedLocation: AppRoutes.verifyOtp,
    );

    expect(redirect, isNull);
  });

  test('authenticated user is redirected away from verify otp', () {
    final redirect = appRedirect(
      sessionState: SessionState.authenticated(
        AppSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2026, 7, 30),
        ),
      ),
      otpChallenge: AuthOtpChallenge.registration(email: 'user@example.com'),
      deepLinks: deepLinks,
      uri: Uri.parse(AppRoutes.verifyOtp),
      matchedLocation: AppRoutes.verifyOtp,
    );

    expect(redirect, AppRoutes.appHome);
  });
}
