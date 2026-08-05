import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/features/auth/data/auth_api.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/verify_otp_request.dart';

import 'in_memory_session_storage.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    Future<AuthSessionResult> Function(LoginRequest request)? onLogin,
    Future<String> Function(RegisterRequest request)? onRegister,
    Future<AuthSessionResult> Function(VerifyOtpRequest request)? onVerifyOtp,
    Future<AuthSessionResult> Function(
      TwoFactorLoginRequest request,
      String preAuthAccessToken,
    )?
    onVerifyLoginTwoFactor,
  }) : _onLogin = onLogin,
       _onRegister = onRegister,
       _onVerifyOtp = onVerifyOtp,
       _onVerifyLoginTwoFactor = onVerifyLoginTwoFactor,
       super(
         api: _NoopAuthApi(),
         sessionRepository: SessionRepository(
           storage: InMemorySessionStorage(),
           config: AppConfig(
             apiBaseUrl: Uri.parse('https://api.example.com/api'),
             flavor: AppFlavor.dev,
             paymentReturnUrl: Uri.parse('skvi://payment/result'),
             paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
           ),
         ),
       );

  final Future<AuthSessionResult> Function(LoginRequest request)? _onLogin;
  final Future<String> Function(RegisterRequest request)? _onRegister;
  final Future<AuthSessionResult> Function(VerifyOtpRequest request)?
  _onVerifyOtp;
  final Future<AuthSessionResult> Function(
    TwoFactorLoginRequest request,
    String preAuthAccessToken,
  )?
  _onVerifyLoginTwoFactor;
  int loginCallCount = 0;
  final List<LoginRequest> loginRequests = <LoginRequest>[];
  int registerCallCount = 0;
  final List<RegisterRequest> registerRequests = <RegisterRequest>[];
  int verifyOtpCallCount = 0;
  final List<VerifyOtpRequest> verifyOtpRequests = <VerifyOtpRequest>[];
  int verifyLoginTwoFactorCallCount = 0;
  final List<TwoFactorLoginRequest> verifyLoginTwoFactorRequests =
      <TwoFactorLoginRequest>[];
  final List<String> verifyLoginTwoFactorTokens = <String>[];

  @override
  Future<AuthSessionResult> login(LoginRequest request) async {
    loginCallCount += 1;
    loginRequests.add(request);
    if (_onLogin != null) {
      return _onLogin(request);
    }
    throw UnimplementedError('FakeAuthRepository.onLogin was not provided.');
  }

  @override
  Future<String> logout(LogoutRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<String> register(RegisterRequest request) {
    registerCallCount += 1;
    registerRequests.add(request);
    if (_onRegister != null) {
      return _onRegister(request);
    }
    throw UnimplementedError('FakeAuthRepository.onRegister was not provided.');
  }

  @override
  Future<AuthSessionResult> verifyOtp(VerifyOtpRequest request) async {
    verifyOtpCallCount += 1;
    verifyOtpRequests.add(request);
    if (_onVerifyOtp != null) {
      return _onVerifyOtp(request);
    }
    throw UnimplementedError(
      'FakeAuthRepository.onVerifyOtp was not provided.',
    );
  }

  @override
  Future<AuthSessionResult> verifyLoginTwoFactor({
    required TwoFactorLoginRequest request,
    required String preAuthAccessToken,
  }) async {
    verifyLoginTwoFactorCallCount += 1;
    verifyLoginTwoFactorRequests.add(request);
    verifyLoginTwoFactorTokens.add(preAuthAccessToken);
    if (_onVerifyLoginTwoFactor != null) {
      return _onVerifyLoginTwoFactor(request, preAuthAccessToken);
    }
    throw UnimplementedError(
      'FakeAuthRepository.onVerifyLoginTwoFactor was not provided.',
    );
  }
}

class _NoopAuthApi extends AuthApi {
  _NoopAuthApi()
    : super(apiClient: ApiClient(Dio()), errorMapper: const DioErrorMapper());
}
