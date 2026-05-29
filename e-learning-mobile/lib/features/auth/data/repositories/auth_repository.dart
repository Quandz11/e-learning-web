import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_tokens.dart';
import '../../../../core/auth/user_session.dart';
import '../../../../core/network/network_providers.dart';
import '../models/auth_requests.dart';
import '../models/auth_response_model.dart';
import '../models/auth_user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(response);
  }

  Future<void> register(RegisterRequestModel request) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: request.toJson(),
    );
  }

  Future<AuthResponseModel> verifyOtp(String email, String otp) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {'email': email, 'otp': otp},
    );
    return AuthResponseModel.fromJson(response);
  }

  Future<AuthResponseModel> refresh(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResponseModel.fromJson(response);
  }

  Future<void> logout(String refreshToken) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<AuthUserModel> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/profile/me');
    return AuthUserModel.fromJson(response);
  }

  UserSession buildSession(
    AuthResponseModel auth,
    AuthUserModel user, {
    String? fallbackRefreshToken,
  }) {
    final refreshToken = auth.refreshToken ?? fallbackRefreshToken ?? '';
    return UserSession(
      user: user,
      tokens: AuthTokens(
        accessToken: auth.accessToken,
        refreshToken: refreshToken,
        expiresAt: auth.expiresAt,
      ),
    );
  }

  AuthUserModel decodeUserFromJwt(String accessToken) {
    final sections = accessToken.split('.');
    if (sections.length < 2) {
      return const AuthUserModel(
        id: '',
        email: '',
        fullName: '',
        role: 'STUDENT',
      );
    }

    final normalized = base64Url.normalize(sections[1]);
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(normalized)))
            as Map<String, dynamic>;

    final role =
        payload['role']?.toString() ??
        payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
            ?.toString() ??
        'STUDENT';

    return AuthUserModel(
      id: payload['sub']?.toString() ?? '',
      email: payload['email']?.toString() ?? '',
      fullName: payload['fullName']?.toString() ?? '',
      role: role,
      avatarUrl: payload['avatarUrl']?.toString(),
    );
  }
}
