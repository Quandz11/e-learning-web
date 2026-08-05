import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/auth/data/models/auth_token_response.dart';
import 'package:e_learning_mobile/features/auth/data/models/login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/message_response.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/verify_otp_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auth models', () {
    test('login request serialization', () {
      const request = LoginRequest(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(request.toJson(), {
        'email': 'user@example.com',
        'password': 'secret',
      });
    });

    test('register request serialization', () {
      const request = RegisterRequest(
        email: 'user@example.com',
        password: 'secret',
        fullName: 'User Name',
        phone: '0123',
        referralCode: 'ABC123',
      );

      expect(request.toJson(), {
        'email': 'user@example.com',
        'password': 'secret',
        'fullName': 'User Name',
        'phone': '0123',
        'referralCode': 'ABC123',
      });
    });

    test('otp request serialization', () {
      const request = VerifyOtpRequest(
        email: 'user@example.com',
        otp: '123456',
      );

      expect(request.toJson(), {'email': 'user@example.com', 'otp': '123456'});
    });

    test('logout request serialization', () {
      const request = LogoutRequest(refreshToken: 'refresh-token');

      expect(request.toJson(), {'refreshToken': 'refresh-token'});
    });

    test('two factor login request serialization', () {
      const request = TwoFactorLoginRequest(code: '123456');

      expect(request.toJson(), {'code': '123456'});
    });

    test('token response parsing', () {
      final response = AuthTokenResponse.fromJson(const {
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'expiresAt': '2026-07-29T12:00:00Z',
        'requiresTwoFactor': true,
        'message': 'Account verified.',
      });

      expect(response.accessToken, 'access');
      expect(response.refreshToken, 'refresh');
      expect(response.expiresAt, DateTime.parse('2026-07-29T12:00:00Z'));
      expect(response.requiresTwoFactor, isTrue);
      expect(response.message, 'Account verified.');
    });

    test('message response parsing', () {
      final response = MessageResponse.fromJson(const {
        'message': 'Registration successful. Please verify your email.',
      });

      expect(
        response.message,
        'Registration successful. Please verify your email.',
      );
    });

    test('nullable optional fields are preserved', () {
      const request = RegisterRequest(
        email: 'user@example.com',
        password: 'secret',
        fullName: 'User Name',
      );

      expect(request.toJson(), {
        'email': 'user@example.com',
        'password': 'secret',
        'fullName': 'User Name',
        'phone': null,
        'referralCode': null,
      });

      const logout = LogoutRequest();
      expect(logout.toJson(), {'refreshToken': null});
    });

    test('malformed token payload throws normalized failure', () {
      expect(
        () => AuthTokenResponse.fromJson(const {
          'accessToken': 'access',
          'expiresAt': '2026-07-29T12:00:00Z',
        }),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.type,
            'type',
            AppFailureType.malformedResponse,
          ),
        ),
      );
    });

    test('malformed expiry value throws normalized failure', () {
      expect(
        () => AuthTokenResponse.fromJson(const {
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'expiresAt': 'not-a-date',
        }),
        throwsA(isA<AppFailure>()),
      );
    });
  });
}
