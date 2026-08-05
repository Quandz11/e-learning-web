import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authOtpChallengeControllerProvider =
    StateNotifierProvider<AuthOtpChallengeController, AuthOtpChallenge?>((ref) {
      return AuthOtpChallengeController();
    });

class AuthOtpChallengeController extends StateNotifier<AuthOtpChallenge?> {
  AuthOtpChallengeController() : super(null);

  void setChallenge(AuthOtpChallenge challenge) {
    state = challenge.isValid ? challenge : null;
  }

  void clear() {
    state = null;
  }
}
