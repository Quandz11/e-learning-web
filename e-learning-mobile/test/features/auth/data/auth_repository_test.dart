import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/features/auth/data/auth_api.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/verify_otp_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_session_storage.dart';
import '../../../helpers/queued_dio_adapter.dart';

void main() {
  group('AuthRepository', () {
    late InMemorySessionStorage storage;
    late QueuedDioAdapter adapter;
    late AuthRepository repository;

    setUp(() {
      storage = InMemorySessionStorage();
      adapter = QueuedDioAdapter();
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.example.com/api',
          headers: const {'Content-Type': 'application/json'},
        ),
      )..httpClientAdapter = adapter;
      final api = AuthApi(
        apiClient: ApiClient(dio),
        errorMapper: const DioErrorMapper(),
      );
      final sessionRepository = SessionRepository(
        storage: storage,
        config: AppConfig(
          apiBaseUrl: Uri.parse('https://api.example.com/api'),
          flavor: AppFlavor.dev,
          paymentReturnUrl: Uri.parse('skvi://payment/result'),
          paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
        ),
      );
      repository = AuthRepository(
        api: api,
        sessionRepository: sessionRepository,
      );
    });

    test('successful login persists session', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/login',
        statusCode: 200,
        body: const {
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'expiresAt': '2026-07-29T12:00:00Z',
          'requiresTwoFactor': false,
        },
      );

      final result = await repository.login(
        const LoginRequest(email: 'user@example.com', password: 'secret'),
      );

      expect(result.session?.accessToken, 'access');
      expect(result.requiresTwoFactor, isFalse);
      expect(await storage.read(), isNotNull);
    });

    test('login requiring two factor does not persist session', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/login',
        statusCode: 200,
        body: const {
          'accessToken': 'pre-auth-access',
          'refreshToken': '',
          'expiresAt': '2026-07-29T12:00:00Z',
          'requiresTwoFactor': true,
        },
      );

      final result = await repository.login(
        const LoginRequest(email: 'user@example.com', password: 'secret'),
      );

      expect(result.requiresTwoFactor, isTrue);
      expect(result.session, isNull);
      expect(await storage.read(), isNull);
    });

    test('successful otp verification persists session', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/verify-otp',
        statusCode: 200,
        body: const {
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'expiresAt': '2026-07-29T12:00:00Z',
          'message': 'Account verified.',
        },
      );

      final result = await repository.verifyOtp(
        const VerifyOtpRequest(email: 'user@example.com', otp: '123456'),
      );

      expect(result.message, 'Account verified.');
      expect((await storage.read())?.refreshToken, 'refresh');
    });

    test('successful login two factor verification persists session', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/2fa/login-verify',
        statusCode: 200,
        body: const {
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'expiresAt': '2026-07-29T12:00:00Z',
        },
      );

      final result = await repository.verifyLoginTwoFactor(
        request: const TwoFactorLoginRequest(code: '123456'),
        preAuthAccessToken: 'pre-auth-token',
      );

      expect(result.session?.accessToken, 'access');
      expect((await storage.read())?.refreshToken, 'refresh');
      expect(
        adapter
            .lastRequest('POST', '/auth/2fa/login-verify')
            .headers['Authorization'],
        'Bearer pre-auth-token',
      );
    });

    test('registration success does not create unsupported session', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/register',
        statusCode: 200,
        body: const {
          'message': 'Registration successful. Please verify your email.',
        },
      );

      final message = await repository.register(
        const RegisterRequest(
          email: 'user@example.com',
          password: 'secret',
          fullName: 'User Name',
        ),
      );

      expect(message, 'Registration successful. Please verify your email.');
      expect(await storage.read(), isNull);
    });

    test('failed login does not alter existing session', () async {
      storage.storedSession = AppSession(
        accessToken: 'existing-access',
        refreshToken: 'existing-refresh',
        expiresAt: DateTime.utc(2026, 7, 29, 12),
      );
      adapter.enqueue(
        method: 'POST',
        path: '/auth/login',
        statusCode: 401,
        body: const {
          'code': 'AUTH_LOGIN_FAILED',
          'message': 'Invalid credentials.',
          'errors': null,
        },
      );

      await expectLater(
        () => repository.login(
          const LoginRequest(email: 'user@example.com', password: 'bad'),
        ),
        throwsA(isA<AppFailure>()),
      );

      expect((await storage.read())?.accessToken, 'existing-access');
    });

    test('failed otp verification does not alter existing session', () async {
      storage.storedSession = AppSession(
        accessToken: 'existing-access',
        refreshToken: 'existing-refresh',
        expiresAt: DateTime.utc(2026, 7, 29, 12),
      );
      adapter.enqueue(
        method: 'POST',
        path: '/auth/2fa/login-verify',
        statusCode: 401,
        body: const {
          'code': 'AUTH_2FA_VERIFY_FAILED',
          'message': 'Invalid 2FA code.',
          'errors': null,
        },
      );

      await expectLater(
        () => repository.verifyLoginTwoFactor(
          request: const TwoFactorLoginRequest(code: '123456'),
          preAuthAccessToken: 'pre-auth-token',
        ),
        throwsA(isA<AppFailure>()),
      );

      expect((await storage.read())?.accessToken, 'existing-access');
    });

    test('malformed otp success response does not authenticate', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/2fa/login-verify',
        statusCode: 200,
        body: const {
          'accessToken': 'access',
          'expiresAt': '2026-07-29T12:00:00Z',
        },
      );

      await expectLater(
        () => repository.verifyLoginTwoFactor(
          request: const TwoFactorLoginRequest(code: '123456'),
          preAuthAccessToken: 'pre-auth-token',
        ),
        throwsA(isA<AppFailure>()),
      );

      expect(await storage.read(), isNull);
    });

    test('logout clears the local session', () async {
      storage.storedSession = AppSession(
        accessToken: 'existing-access',
        refreshToken: 'existing-refresh',
        expiresAt: DateTime.utc(2026, 7, 29, 12),
      );
      adapter.enqueue(
        method: 'POST',
        path: '/auth/logout',
        statusCode: 200,
        body: const {'message': 'Logged out successfully.'},
      );

      final message = await repository.logout(
        const LogoutRequest(refreshToken: 'existing-refresh'),
      );

      expect(message, 'Logged out successfully.');
      expect(await storage.read(), isNull);
    });

    test('remote logout failure still follows local clear behavior', () async {
      storage.storedSession = AppSession(
        accessToken: 'existing-access',
        refreshToken: 'existing-refresh',
        expiresAt: DateTime.utc(2026, 7, 29, 12),
      );
      adapter.enqueue(
        method: 'POST',
        path: '/auth/logout',
        statusCode: 401,
        body: const {
          'code': 'AUTH_LOGOUT_FAILED',
          'message': 'Logout failed.',
          'errors': null,
        },
      );

      await expectLater(
        () => repository.logout(
          const LogoutRequest(refreshToken: 'existing-refresh'),
        ),
        throwsA(isA<AppFailure>()),
      );

      expect(await storage.read(), isNull);
    });
  });
}
