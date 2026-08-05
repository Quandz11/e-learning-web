enum AuthOtpChallengeType { registration, loginTwoFactor }

class AuthOtpChallenge {
  const AuthOtpChallenge({
    required this.email,
    required this.type,
    this.preAuthAccessToken,
    this.displayMessage,
  });

  factory AuthOtpChallenge.registration({
    required String email,
    String? displayMessage,
  }) {
    return AuthOtpChallenge(
      email: email.trim(),
      type: AuthOtpChallengeType.registration,
      displayMessage: displayMessage?.trim(),
    );
  }

  factory AuthOtpChallenge.loginTwoFactor({
    required String email,
    required String preAuthAccessToken,
    String? displayMessage,
  }) {
    return AuthOtpChallenge(
      email: email.trim(),
      type: AuthOtpChallengeType.loginTwoFactor,
      preAuthAccessToken: preAuthAccessToken.trim(),
      displayMessage: displayMessage?.trim(),
    );
  }

  final String email;
  final AuthOtpChallengeType type;
  final String? preAuthAccessToken;
  final String? displayMessage;

  bool get isValid {
    if (email.trim().isEmpty) {
      return false;
    }
    if (type == AuthOtpChallengeType.loginTwoFactor) {
      return (preAuthAccessToken?.trim().isNotEmpty ?? false);
    }
    return true;
  }
}
