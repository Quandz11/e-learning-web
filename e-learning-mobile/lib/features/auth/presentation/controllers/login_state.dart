import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';

enum LoginStatus { idle, submitting, success, failure, twoFactorRequired }

class LoginState {
  const LoginState({
    this.status = LoginStatus.idle,
    this.emailError,
    this.passwordError,
    this.generalMessage,
    this.pendingChallenge,
  });

  final LoginStatus status;
  final String? emailError;
  final String? passwordError;
  final String? generalMessage;
  final AuthOtpChallenge? pendingChallenge;

  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    LoginStatus? status,
    String? emailError,
    bool clearEmailError = false,
    String? passwordError,
    bool clearPasswordError = false,
    String? generalMessage,
    bool clearGeneralMessage = false,
    AuthOtpChallenge? pendingChallenge,
    bool clearPendingChallenge = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      generalMessage: clearGeneralMessage
          ? null
          : (generalMessage ?? this.generalMessage),
      pendingChallenge: clearPendingChallenge
          ? null
          : (pendingChallenge ?? this.pendingChallenge),
    );
  }
}
