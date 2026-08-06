import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final forgotPasswordChallengeControllerProvider =
    StateNotifierProvider<
      ForgotPasswordChallengeController,
      ForgotPasswordChallenge?
    >((ref) {
      return ForgotPasswordChallengeController();
    });

class ForgotPasswordChallengeController
    extends StateNotifier<ForgotPasswordChallenge?> {
  ForgotPasswordChallengeController() : super(null);

  void setChallenge(ForgotPasswordChallenge challenge) {
    state = challenge.isValid ? challenge : null;
  }

  void clear() {
    state = null;
  }
}
