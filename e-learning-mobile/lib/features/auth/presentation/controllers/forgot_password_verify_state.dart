enum ForgotPasswordVerifyStatus { idle, submitting, success, failure }

class ForgotPasswordVerifyState {
  const ForgotPasswordVerifyState({
    this.status = ForgotPasswordVerifyStatus.idle,
    this.otpError,
    this.passwordError,
    this.confirmPasswordError,
    this.generalMessage,
  });

  final ForgotPasswordVerifyStatus status;
  final String? otpError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? generalMessage;

  bool get isSubmitting => status == ForgotPasswordVerifyStatus.submitting;

  ForgotPasswordVerifyState copyWith({
    ForgotPasswordVerifyStatus? status,
    String? otpError,
    bool clearOtpError = false,
    String? passwordError,
    bool clearPasswordError = false,
    String? confirmPasswordError,
    bool clearConfirmPasswordError = false,
    String? generalMessage,
    bool clearGeneralMessage = false,
  }) {
    return ForgotPasswordVerifyState(
      status: status ?? this.status,
      otpError: clearOtpError ? null : (otpError ?? this.otpError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : (confirmPasswordError ?? this.confirmPasswordError),
      generalMessage: clearGeneralMessage
          ? null
          : (generalMessage ?? this.generalMessage),
    );
  }
}
