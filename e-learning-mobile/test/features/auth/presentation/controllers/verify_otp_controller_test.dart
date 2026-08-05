import 'dart:async';

import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/verify_otp_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/verify_otp_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  group('VerifyOtpController', () {
    test('initial state', () {
      final controller = VerifyOtpController(
        authRepository: FakeAuthRepository(
          onVerifyOtp: (_) async => throw UnimplementedError(),
        ),
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      expect(controller.state.status, VerifyOtpStatus.idle);
      expect(controller.state.otpError, isNull);
      expect(controller.state.generalMessage, isNull);
    });

    test('empty otp validation', () async {
      final controller = _buildController();

      await controller.submit(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        otp: '',
      );

      expect(controller.state.otpError, 'Enter the 6-digit code.');
    });

    test('invalid otp shape validation', () async {
      final controller = _buildController();

      await controller.submit(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        otp: '12ab',
      );

      expect(controller.state.otpError, 'Enter a valid 6-digit code.');
    });

    test('valid registration submission calls repository once', () async {
      final repository = FakeAuthRepository(
        onVerifyOtp: (_) async =>
            AuthSessionResult(session: _session(), requiresTwoFactor: false),
      );
      final controller = VerifyOtpController(
        authRepository: repository,
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      await controller.submit(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        otp: '123456',
      );

      expect(repository.verifyOtpCallCount, 1);
      expect(repository.verifyOtpRequests.single.email, 'user@example.com');
      expect(repository.verifyOtpRequests.single.otp, '123456');
    });

    test('submitting state', () async {
      final completer = Completer<AuthSessionResult>();
      final controller = VerifyOtpController(
        authRepository: FakeAuthRepository(
          onVerifyOtp: (_) => completer.future,
        ),
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      unawaited(
        controller.submit(
          challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
          otp: '123456',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, VerifyOtpStatus.submitting);

      completer.complete(
        AuthSessionResult(session: _session(), requiresTwoFactor: false),
      );
      await Future<void>.delayed(Duration.zero);
    });

    test('success state authenticates and clears challenge', () async {
      final sessionController = _buildSessionController();
      final challengeController = AuthOtpChallengeController()
        ..setChallenge(
          AuthOtpChallenge.registration(email: 'user@example.com'),
        );
      final controller = VerifyOtpController(
        authRepository: FakeAuthRepository(
          onVerifyOtp: (_) async =>
              AuthSessionResult(session: _session(), requiresTwoFactor: false),
        ),
        sessionController: sessionController,
        challengeController: challengeController,
      );

      await controller.submit(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        otp: '123456',
      );

      expect(controller.state.status, VerifyOtpStatus.success);
      expect(sessionController.state.status, SessionStatus.authenticated);
      expect(challengeController.state, isNull);
    });

    test('failure state maps backend field errors', () async {
      final controller = VerifyOtpController(
        authRepository: FakeAuthRepository(
          onVerifyOtp: (_) async => throw const AppFailure(
            type: AppFailureType.validation,
            message: 'Validation failed.',
            validationErrors: {
              'otp': ['Code is invalid.'],
            },
          ),
        ),
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      await controller.submit(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        otp: '123456',
      );

      expect(controller.state.status, VerifyOtpStatus.failure);
      expect(controller.state.otpError, 'Code is invalid.');
    });

    test('duplicate-submit prevention', () async {
      final completer = Completer<AuthSessionResult>();
      final repository = FakeAuthRepository(
        onVerifyOtp: (_) => completer.future,
      );
      final controller = VerifyOtpController(
        authRepository: repository,
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      unawaited(
        controller.submit(
          challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
          otp: '123456',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      unawaited(
        controller.submit(
          challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
          otp: '123456',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.verifyOtpCallCount, 1);
      completer.complete(
        AuthSessionResult(session: _session(), requiresTwoFactor: false),
      );
      await Future<void>.delayed(Duration.zero);
    });

    test('recovery after failure', () async {
      final controller = VerifyOtpController(
        authRepository: FakeAuthRepository(
          onVerifyOtp: (_) async => throw const AppFailure(
            type: AppFailureType.unauthorized,
            message: 'Invalid OTP.',
          ),
        ),
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      await controller.submit(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        otp: '123456',
      );
      controller.onOtpChanged();

      expect(controller.state.status, VerifyOtpStatus.idle);
      expect(controller.state.generalMessage, isNull);
    });

    test('registration challenge behavior', () async {
      final controller = VerifyOtpController(
        authRepository: FakeAuthRepository(
          onVerifyOtp: (_) async =>
              AuthSessionResult(session: _session(), requiresTwoFactor: false),
        ),
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      await controller.submit(
        challenge: AuthOtpChallenge.registration(email: 'user@example.com'),
        otp: '123456',
      );

      expect(controller.state.status, VerifyOtpStatus.success);
    });

    test('login 2fa challenge behavior', () async {
      final repository = FakeAuthRepository(
        onVerifyLoginTwoFactor: (_, __) async =>
            AuthSessionResult(session: _session(), requiresTwoFactor: false),
      );
      final controller = VerifyOtpController(
        authRepository: repository,
        sessionController: _buildSessionController(),
        challengeController: AuthOtpChallengeController(),
      );

      await controller.submit(
        challenge: AuthOtpChallenge.loginTwoFactor(
          email: 'user@example.com',
          preAuthAccessToken: 'pre-auth-token',
        ),
        otp: '123456',
      );

      expect(repository.verifyLoginTwoFactorCallCount, 1);
      expect(repository.verifyLoginTwoFactorRequests.single.code, '123456');
      expect(repository.verifyLoginTwoFactorTokens.single, 'pre-auth-token');
    });

    test('missing login 2fa pre-auth token fails safely', () async {
      final controller = _buildController();

      await controller.submit(
        challenge: const AuthOtpChallenge(
          email: 'user@example.com',
          type: AuthOtpChallengeType.loginTwoFactor,
        ),
        otp: '123456',
      );

      expect(controller.state.status, VerifyOtpStatus.failure);
      expect(
        controller.state.generalMessage,
        'Your verification session is no longer available. Please sign in again.',
      );
    });
  });
}

VerifyOtpController _buildController() {
  return VerifyOtpController(
    authRepository: FakeAuthRepository(
      onVerifyOtp: (_) async => throw UnimplementedError(),
    ),
    sessionController: _buildSessionController(),
    challengeController: AuthOtpChallengeController(),
  );
}

SessionController _buildSessionController() {
  return SessionController(
    SessionRepository(
      storage: InMemorySessionStorage(),
      config: AppConfig(
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
        flavor: AppFlavor.dev,
        paymentReturnUrl: Uri.parse('skvi://payment/result'),
        paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
      ),
    ),
  );
}

AppSession _session() {
  return AppSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2026, 7, 30),
  );
}
