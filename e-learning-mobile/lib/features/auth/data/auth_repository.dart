import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/features/auth/data/auth_api.dart';
import 'package:e_learning_mobile/features/auth/data/models/login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/phone_forgot_password_otp_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/phone_forgot_password_otp_verify_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_disable_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_enable_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_setup_response.dart';
import 'package:e_learning_mobile/features/auth/data/models/verify_otp_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.read(authApiProvider),
    sessionRepository: ref.read(sessionRepositoryProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SessionRepository sessionRepository,
  }) : _api = api,
       _sessionRepository = sessionRepository;

  final AuthApi _api;
  final SessionRepository _sessionRepository;

  Future<AuthSessionResult> login(LoginRequest request) async {
    final response = await _api.login(request);
    if (response.requiresTwoFactor ?? false) {
      return AuthSessionResult(
        session: null,
        requiresTwoFactor: true,
        preAuthAccessToken: response.accessToken,
        message:
            response.message ??
            'Two-factor authentication is required to complete sign in.',
      );
    }

    final session = response.toSession();
    await _sessionRepository.writeSession(session);
    return AuthSessionResult(
      session: session,
      requiresTwoFactor: false,
      message: response.message,
    );
  }

  Future<String> register(RegisterRequest request) async {
    final response = await _api.register(request);
    return response.message;
  }

  Future<AuthSessionResult> verifyOtp(VerifyOtpRequest request) async {
    final response = await _api.verifyOtp(request);
    final session = response.toSession();
    await _sessionRepository.writeSession(session);
    return AuthSessionResult(
      session: session,
      requiresTwoFactor: response.requiresTwoFactor ?? false,
      message: response.message,
    );
  }

  Future<AuthSessionResult> verifyLoginTwoFactor({
    required TwoFactorLoginRequest request,
    required String preAuthAccessToken,
  }) async {
    final response = await _api.verifyLoginTwoFactor(
      request: request,
      preAuthAccessToken: preAuthAccessToken,
    );
    final session = response.toSession();
    await _sessionRepository.writeSession(session);
    return AuthSessionResult(
      session: session,
      requiresTwoFactor: response.requiresTwoFactor ?? false,
      message: response.message,
    );
  }

  Future<TwoFactorSetupResponse> setupTwoFactor() => _api.setupTwoFactor();

  Future<AuthSessionResult> enableTwoFactor({
    required String secret,
    required String code,
  }) async {
    final response = await _api.enableTwoFactor(
      TwoFactorEnableRequest(secret: secret, code: code),
    );
    final session = response.toSession();
    await _sessionRepository.writeSession(session);
    return AuthSessionResult(
      session: session,
      requiresTwoFactor: response.requiresTwoFactor ?? false,
      message: response.message,
    );
  }

  Future<String> disableTwoFactor({required String password}) async {
    final response = await _api.disableTwoFactor(
      TwoFactorDisableRequest(password: password),
    );
    return response.message;
  }

  Future<String> logout(LogoutRequest request) async {
    try {
      final response = await _api.logout(request);
      return response.message;
    } finally {
      await _sessionRepository.clear();
    }
  }

  Future<String> requestForgotPasswordOtp(String phone) async {
    final response = await _api.requestForgotPasswordOtp(
      PhoneForgotPasswordOtpRequest(phone: phone),
    );
    return response.message;
  }

  Future<String> resendForgotPasswordOtp(String phone) async {
    final response = await _api.resendForgotPasswordOtp(
      PhoneForgotPasswordOtpRequest(phone: phone),
    );
    return response.message;
  }

  Future<String> verifyForgotPasswordOtp({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _api.verifyForgotPasswordOtp(
      PhoneForgotPasswordOtpVerifyRequest(
        phone: phone,
        otp: otp,
        newPassword: newPassword,
      ),
    );
    return response.message;
  }

  Future<String> requestEmailForgotPasswordOtp(String email) async {
    final response = await _api.requestEmailForgotPasswordOtp(email);
    return response.message;
  }

  Future<String> resendEmailForgotPasswordOtp(String email) async {
    final response = await _api.resendEmailForgotPasswordOtp(email);
    return response.message;
  }

  Future<String> verifyEmailForgotPasswordOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _api.verifyEmailForgotPasswordOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    return response.message;
  }
}

class AuthSessionResult {
  const AuthSessionResult({
    required this.session,
    required this.requiresTwoFactor,
    this.preAuthAccessToken,
    this.message,
  });

  final AppSession? session;
  final bool requiresTwoFactor;
  final String? preAuthAccessToken;
  final String? message;
}
