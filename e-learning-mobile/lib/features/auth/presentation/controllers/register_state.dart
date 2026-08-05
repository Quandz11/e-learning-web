enum RegisterStatus { idle, submitting, success, failure }

class RegisterState {
  const RegisterState({
    this.status = RegisterStatus.idle,
    this.fullNameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.phoneError,
    this.referralCodeError,
    this.generalMessage,
    this.submittedEmail,
  });

  final RegisterStatus status;
  final String? fullNameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? phoneError;
  final String? referralCodeError;
  final String? generalMessage;
  final String? submittedEmail;

  bool get isSubmitting => status == RegisterStatus.submitting;

  RegisterState copyWith({
    RegisterStatus? status,
    String? fullNameError,
    bool clearFullNameError = false,
    String? emailError,
    bool clearEmailError = false,
    String? passwordError,
    bool clearPasswordError = false,
    String? confirmPasswordError,
    bool clearConfirmPasswordError = false,
    String? phoneError,
    bool clearPhoneError = false,
    String? referralCodeError,
    bool clearReferralCodeError = false,
    String? generalMessage,
    bool clearGeneralMessage = false,
    String? submittedEmail,
    bool clearSubmittedEmail = false,
  }) {
    return RegisterState(
      status: status ?? this.status,
      fullNameError: clearFullNameError
          ? null
          : (fullNameError ?? this.fullNameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : (confirmPasswordError ?? this.confirmPasswordError),
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      referralCodeError: clearReferralCodeError
          ? null
          : (referralCodeError ?? this.referralCodeError),
      generalMessage: clearGeneralMessage
          ? null
          : (generalMessage ?? this.generalMessage),
      submittedEmail: clearSubmittedEmail
          ? null
          : (submittedEmail ?? this.submittedEmail),
    );
  }
}
