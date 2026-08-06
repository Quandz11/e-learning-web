import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/features/auth/data/auth_api.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/auth_token_response.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/login_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  group('LoginController', () {
    test('initial state', () {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => throw UnimplementedError(),
        ),
        sessionController: _buildSessionController(),
      );

      expect(controller.state.status, LoginStatus.idle);
      expect(controller.state.emailError, isNull);
      expect(controller.state.passwordError, isNull);
      expect(controller.state.generalMessage, isNull);
    });

    test('empty email validation', () async {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => throw UnimplementedError(),
        ),
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: '', password: 'secret');

      expect(controller.state.emailError, 'Vui lòng nhập email.');
      expect(controller.state.status, LoginStatus.failure);
    });

    test('invalid email validation', () async {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => throw UnimplementedError(),
        ),
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: 'invalid', password: 'secret');

      expect(controller.state.emailError, 'Email không hợp lệ.');
    });

    test('empty password validation', () async {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => throw UnimplementedError(),
        ),
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: 'user@example.com', password: '');

      expect(controller.state.passwordError, 'Vui lòng nhập mật khẩu.');
    });

    test('valid submission calls repository once', () async {
      final repository = FakeAuthRepository(
        onLogin: (_) async =>
            AuthSessionResult(session: _session(), requiresTwoFactor: false),
      );
      final controller = LoginController(
        authRepository: repository,
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: ' user@example.com ', password: 'secret');

      expect(repository.loginCallCount, 1);
      expect(repository.loginRequests.single.email, 'user@example.com');
    });

    test('submitting state', () async {
      final completer = Completer<AuthSessionResult>();
      final repository = FakeAuthRepository(onLogin: (_) => completer.future);
      final controller = LoginController(
        authRepository: repository,
        sessionController: _buildSessionController(),
      );

      unawaited(
        controller.submit(email: 'user@example.com', password: 'secret'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, LoginStatus.submitting);

      completer.complete(
        AuthSessionResult(session: _session(), requiresTwoFactor: false),
      );
      await Future<void>.delayed(Duration.zero);
    });

    test('successful login', () async {
      final sessionController = _buildSessionController();
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async =>
              AuthSessionResult(session: _session(), requiresTwoFactor: false),
        ),
        sessionController: sessionController,
      );

      await controller.submit(email: 'user@example.com', password: 'secret');

      expect(controller.state.status, LoginStatus.success);
      expect(sessionController.state.status, SessionStatus.authenticated);
    });

    test('failed login', () async {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => throw const AppFailure(
            type: AppFailureType.unauthorized,
            message: 'Invalid credentials.',
          ),
        ),
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: 'user@example.com', password: 'bad');

      expect(controller.state.status, LoginStatus.failure);
      expect(controller.state.generalMessage, 'Invalid credentials.');
    });

    test('backend field errors', () async {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => throw const AppFailure(
            type: AppFailureType.validation,
            message: 'Validation failed.',
            validationErrors: {
              'email': ['Email is invalid.'],
              'password': ['Password is required.'],
            },
          ),
        ),
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: 'user@example.com', password: 'secret');

      expect(controller.state.emailError, 'Email is invalid.');
      expect(controller.state.passwordError, 'Password is required.');
    });

    test('duplicate-submit prevention', () async {
      final completer = Completer<AuthSessionResult>();
      final repository = FakeAuthRepository(onLogin: (_) => completer.future);
      final controller = LoginController(
        authRepository: repository,
        sessionController: _buildSessionController(),
      );

      unawaited(
        controller.submit(email: 'user@example.com', password: 'secret'),
      );
      await Future<void>.delayed(Duration.zero);
      unawaited(
        controller.submit(email: 'user@example.com', password: 'secret'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.loginCallCount, 1);

      completer.complete(
        AuthSessionResult(session: _session(), requiresTwoFactor: false),
      );
      await Future<void>.delayed(Duration.zero);
    });

    test('recovery after failure', () async {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => throw const AppFailure(
            type: AppFailureType.unauthorized,
            message: 'Invalid credentials.',
          ),
        ),
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: 'user@example.com', password: 'bad');
      controller.onEmailChanged();

      expect(controller.state.generalMessage, isNull);
      expect(controller.state.status, LoginStatus.idle);
    });

    test('requiresTwoFactor true behavior', () async {
      final sessionController = _buildSessionController();
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async => const AuthSessionResult(
            session: null,
            requiresTwoFactor: true,
            preAuthAccessToken: 'pre-auth-token',
            message:
                'Two-factor authentication is required to complete sign in.',
          ),
        ),
        sessionController: sessionController,
      );

      await controller.submit(email: 'user@example.com', password: 'secret');

      expect(controller.state.status, LoginStatus.twoFactorRequired);
      expect(controller.state.pendingChallenge, isNotNull);
      expect(
        controller.state.pendingChallenge?.type,
        AuthOtpChallengeType.loginTwoFactor,
      );
      expect(
        sessionController.state.status,
        isNot(SessionStatus.authenticated),
      );
    });

    test('missing pre-auth token becomes failure', () async {
      final controller = LoginController(
        authRepository: FakeAuthRepository(
          onLogin: (_) async =>
              const AuthSessionResult(session: null, requiresTwoFactor: true),
        ),
        sessionController: _buildSessionController(),
      );

      await controller.submit(email: 'user@example.com', password: 'secret');

      expect(controller.state.status, LoginStatus.failure);
      expect(
        controller.state.generalMessage,
        'Phản hồi đăng nhập chưa đầy đủ. Vui lòng thử lại.',
      );
    });

    test('no session duplication in controller', () async {
      final storage = CountingSessionStorage();
      final authRepository = AuthRepository(
        api: _SuccessfulAuthApi(),
        sessionRepository: _buildSessionRepository(storage),
      );
      final sessionController = SessionController(
        _buildSessionRepository(storage),
      );
      final controller = LoginController(
        authRepository: authRepository,
        sessionController: sessionController,
      );

      await controller.submit(email: 'user@example.com', password: 'secret');

      expect(storage.writeCount, 1);
      expect(sessionController.state.session?.accessToken, 'access');
    });
  });
}

SessionController _buildSessionController() {
  return SessionController(_buildSessionRepository(InMemorySessionStorage()));
}

SessionRepository _buildSessionRepository(InMemorySessionStorage storage) {
  return SessionRepository(
    storage: storage,
    config: AppConfig(
      apiBaseUrl: Uri.parse('https://api.example.com/api'),
      flavor: AppFlavor.dev,
      paymentReturnUrl: Uri.parse('skvi://payment/result'),
      paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
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

class _SuccessfulAuthApi extends AuthApi {
  _SuccessfulAuthApi()
    : super(apiClient: ApiClient(Dio()), errorMapper: const DioErrorMapper());

  @override
  Future<AuthTokenResponse> login(request) async {
    return AuthTokenResponse(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: DateTime.utc(2026, 7, 30),
      requiresTwoFactor: false,
    );
  }
}

class CountingSessionStorage extends InMemorySessionStorage {
  int writeCount = 0;

  @override
  Future<void> write(AppSession session) async {
    writeCount += 1;
    await super.write(session);
  }
}
