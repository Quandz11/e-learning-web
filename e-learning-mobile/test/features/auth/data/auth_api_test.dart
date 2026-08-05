import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/auth/data/auth_api.dart';
import 'package:e_learning_mobile/features/auth/data/models/login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/verify_otp_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/queued_dio_adapter.dart';

void main() {
  group('AuthApi', () {
    late QueuedDioAdapter adapter;
    late AuthApi api;

    setUp(() {
      adapter = QueuedDioAdapter();
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.example.com/api',
          headers: const {'Content-Type': 'application/json'},
        ),
      )..httpClientAdapter = adapter;
      api = AuthApi(
        apiClient: ApiClient(dio),
        errorMapper: const DioErrorMapper(),
      );
    });

    test('login uses correct method path body and parses success', () async {
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

      final response = await api.login(
        const LoginRequest(email: 'user@example.com', password: 'secret'),
      );

      final request = adapter.lastRequest('POST', '/auth/login');
      expect(request.body, {'email': 'user@example.com', 'password': 'secret'});
      expect(response.accessToken, 'access');
      expect(response.requiresTwoFactor, isFalse);
    });

    test('login parses two factor pre-auth success', () async {
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

      final response = await api.login(
        const LoginRequest(email: 'user@example.com', password: 'secret'),
      );

      expect(response.accessToken, 'pre-auth-access');
      expect(response.refreshToken, isEmpty);
      expect(response.requiresTwoFactor, isTrue);
    });

    test('register uses correct method path body and parses success', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/register',
        statusCode: 200,
        body: const {
          'message': 'Registration successful. Please verify your email.',
        },
      );

      final response = await api.register(
        const RegisterRequest(
          email: 'user@example.com',
          password: 'secret',
          fullName: 'User Name',
          phone: null,
          referralCode: null,
        ),
      );

      final request = adapter.lastRequest('POST', '/auth/register');
      expect(request.body, {
        'email': 'user@example.com',
        'password': 'secret',
        'fullName': 'User Name',
        'phone': null,
        'referralCode': null,
      });
      expect(
        response.message,
        'Registration successful. Please verify your email.',
      );
    });

    test(
      'verify otp uses correct method path body and parses success',
      () async {
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

        final response = await api.verifyOtp(
          const VerifyOtpRequest(email: 'user@example.com', otp: '123456'),
        );

        final request = adapter.lastRequest('POST', '/auth/verify-otp');
        expect(request.body, {'email': 'user@example.com', 'otp': '123456'});
        expect(response.message, 'Account verified.');
      },
    );

    test(
      'login two factor verify uses correct method path body and bearer header',
      () async {
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

        final response = await api.verifyLoginTwoFactor(
          request: const TwoFactorLoginRequest(code: '123456'),
          preAuthAccessToken: 'pre-auth-token',
        );

        final request = adapter.lastRequest('POST', '/auth/2fa/login-verify');
        expect(request.body, {'code': '123456'});
        expect(request.headers['Authorization'], 'Bearer pre-auth-token');
        expect(response.accessToken, 'access');
      },
    );

    test('logout uses correct method path body and parses success', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/logout',
        statusCode: 200,
        body: const {'message': 'Logged out successfully.'},
      );

      final response = await api.logout(
        const LogoutRequest(refreshToken: 'refresh-token'),
      );

      final request = adapter.lastRequest('POST', '/auth/logout');
      expect(request.body, {'refreshToken': 'refresh-token'});
      expect(response.message, 'Logged out successfully.');
    });

    test('structured backend error mapping is normalized', () async {
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
        () => api.login(
          const LoginRequest(email: 'user@example.com', password: 'bad'),
        ),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.type,
                'type',
                AppFailureType.unauthorized,
              )
              .having(
                (failure) => failure.backendCode,
                'backendCode',
                'AUTH_LOGIN_FAILED',
              )
              .having(
                (failure) => failure.message,
                'message',
                'Invalid credentials.',
              ),
        ),
      );
    });

    test('simple backend error mapping is normalized', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/register',
        statusCode: 400,
        body: const {'message': 'Registration failed.'},
      );

      await expectLater(
        () => api.register(
          const RegisterRequest(
            email: 'user@example.com',
            password: 'secret',
            fullName: 'User Name',
          ),
        ),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.type,
                'type',
                AppFailureType.business,
              )
              .having(
                (failure) => failure.message,
                'message',
                'Registration failed.',
              ),
        ),
      );
    });

    test('malformed success response becomes normalized failure', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/login',
        statusCode: 200,
        body: const {'accessToken': 'access'},
      );

      await expectLater(
        () => api.login(
          const LoginRequest(email: 'user@example.com', password: 'secret'),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.type,
            'type',
            AppFailureType.malformedResponse,
          ),
        ),
      );
    });

    test('expired otp error is normalized', () async {
      adapter.enqueue(
        method: 'POST',
        path: '/auth/verify-otp',
        statusCode: 401,
        body: const {
          'code': 'AUTH_OTP_INVALID',
          'message': 'OTP has expired.',
          'errors': null,
        },
      );

      await expectLater(
        () => api.verifyOtp(
          const VerifyOtpRequest(email: 'user@example.com', otp: '123456'),
        ),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.backendCode,
                'backendCode',
                'AUTH_OTP_INVALID',
              )
              .having(
                (failure) => failure.message,
                'message',
                'OTP has expired.',
              ),
        ),
      );
    });
  });
}
