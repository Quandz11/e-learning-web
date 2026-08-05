import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';

class AuthTokenResponse {
  const AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.requiresTwoFactor,
    this.message,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    final requiresTwoFactor = json['requiresTwoFactor'];
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final expiresAtRaw = json['expiresAt'];

    final parsedAccessToken = accessToken is String ? accessToken.trim() : '';
    final parsedRefreshToken = refreshToken is String
        ? refreshToken.trim()
        : '';
    final parsedExpiresAt = expiresAtRaw is String
        ? DateTime.tryParse(expiresAtRaw)?.toUtc()
        : null;
    final message = json['message'];

    if (requiresTwoFactor != null && requiresTwoFactor is! bool) {
      throw _malformedTokenFailure();
    }

    final isTwoFactorRequired = requiresTwoFactor as bool? ?? false;

    if (parsedAccessToken.isEmpty || parsedExpiresAt == null) {
      throw _malformedTokenFailure();
    }

    if (!isTwoFactorRequired && parsedRefreshToken.isEmpty) {
      throw _malformedTokenFailure();
    }
    if (message != null && message is! String) {
      throw _malformedTokenFailure();
    }

    return AuthTokenResponse(
      accessToken: parsedAccessToken,
      refreshToken: parsedRefreshToken,
      expiresAt: parsedExpiresAt,
      requiresTwoFactor: isTwoFactorRequired,
      message: message as String?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final bool? requiresTwoFactor;
  final String? message;

  AppSession toSession() {
    if (refreshToken.isEmpty) {
      throw _malformedTokenFailure();
    }
    return AppSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }
}

AppFailure _malformedTokenFailure() {
  return const AppFailure(
    type: AppFailureType.malformedResponse,
    message: 'The server returned an invalid authentication response.',
    debugDetails: 'Malformed auth token payload.',
  );
}
