import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/auth/data/models/auth_token_response.dart';
import 'package:e_learning_mobile/features/auth/data/models/login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/message_response.dart';
import 'package:e_learning_mobile/features/auth/data/models/phone_forgot_password_otp_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/phone_forgot_password_otp_verify_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_disable_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_enable_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_setup_response.dart';
import 'package:e_learning_mobile/features/auth/data/models/verify_otp_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
  );
});

class AuthApi {
  AuthApi({required ApiClient apiClient, required DioErrorMapper errorMapper})
    : _apiClient = apiClient,
      _errorMapper = errorMapper;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;

  Future<AuthTokenResponse> login(LoginRequest request) async {
    return _postTokenResponse('/auth/login', request.toJson());
  }

  Future<MessageResponse> register(RegisterRequest request) async {
    return _postMessageResponse('/auth/register', request.toJson());
  }

  Future<AuthTokenResponse> verifyOtp(VerifyOtpRequest request) async {
    return _postTokenResponse('/auth/verify-otp', request.toJson());
  }

  Future<AuthTokenResponse> verifyLoginTwoFactor({
    required TwoFactorLoginRequest request,
    required String preAuthAccessToken,
  }) async {
    return _postTokenResponse(
      '/auth/2fa/login-verify',
      request.toJson(),
      options: Options(
        headers: <String, dynamic>{
          'Authorization': 'Bearer ${preAuthAccessToken.trim()}',
        },
      ),
    );
  }

  Future<TwoFactorSetupResponse> setupTwoFactor() async {
    final data = await _postJson('/auth/2fa/setup', const <String, dynamic>{});
    try {
      return TwoFactorSetupResponse.fromJson(data);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw _malformedResponseFailure(
        'The server returned an invalid response.',
        error,
      );
    }
  }

  Future<AuthTokenResponse> enableTwoFactor(
    TwoFactorEnableRequest request,
  ) async {
    return _postTokenResponse('/auth/2fa/enable', request.toJson());
  }

  Future<MessageResponse> disableTwoFactor(
    TwoFactorDisableRequest request,
  ) async {
    return _postMessageResponse('/auth/2fa/disable', request.toJson());
  }

  Future<MessageResponse> logout(LogoutRequest request) async {
    return _postMessageResponse('/auth/logout', request.toJson());
  }

  Future<MessageResponse> requestForgotPasswordOtp(
    PhoneForgotPasswordOtpRequest request,
  ) async {
    return _postMessageResponse(
      '/auth/phone/request-forgot-password-otp',
      request.toJson(),
    );
  }

  Future<MessageResponse> resendForgotPasswordOtp(
    PhoneForgotPasswordOtpRequest request,
  ) async {
    return _postMessageResponse(
      '/auth/phone/resend-forgot-password-otp',
      request.toJson(),
    );
  }

  Future<MessageResponse> verifyForgotPasswordOtp(
    PhoneForgotPasswordOtpVerifyRequest request,
  ) async {
    return _postMessageResponse(
      '/auth/phone/verify-forgot-password-otp',
      request.toJson(),
    );
  }

  Future<MessageResponse> requestEmailForgotPasswordOtp(String email) async {
    return _postMessageResponse('/auth/forgot-password', {
      'email': email.trim(),
    });
  }

  Future<MessageResponse> resendEmailForgotPasswordOtp(String email) async {
    return _postMessageResponse('/auth/resend-forgot-password-otp', {
      'email': email.trim(),
    });
  }

  Future<MessageResponse> verifyEmailForgotPasswordOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return _postMessageResponse('/auth/verify-forgot-password-otp', {
      'email': email.trim(),
      'otp': otp.trim(),
      'newPassword': newPassword,
    });
  }

  Future<AuthTokenResponse> _postTokenResponse(
    String path,
    Map<String, dynamic> body, {
    Options? options,
  }) async {
    final data = await _postJson(path, body, options: options);
    try {
      return AuthTokenResponse.fromJson(data);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw _malformedResponseFailure(
        'The server returned an invalid authentication response.',
        error,
      );
    }
  }

  Future<MessageResponse> _postMessageResponse(
    String path,
    Map<String, dynamic> body, {
    Options? options,
  }) async {
    final data = await _postJson(path, body, options: options);
    try {
      return MessageResponse.fromJson(data);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw _malformedResponseFailure(
        'The server returned an invalid response.',
        error,
      );
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    Options? options,
  }) async {
    try {
      final data = await _apiClient.post<Object?>(
        path,
        data: body,
        options: options,
      );
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      throw _malformedResponseFailure(
        'The server returned an invalid response.',
        data,
      );
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is AppFailure) {
        throw mapped;
      }
      throw _errorMapper.map(error);
    }
  }

  AppFailure _malformedResponseFailure(String message, Object? cause) {
    return AppFailure(
      type: AppFailureType.malformedResponse,
      message: message,
      debugDetails: cause?.toString(),
      originalCause: cause,
    );
  }
}
