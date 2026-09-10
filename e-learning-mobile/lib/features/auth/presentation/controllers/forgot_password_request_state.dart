enum ForgotPasswordRequestStatus { idle, submitting, success, failure }

class ForgotPasswordRequestState {
  const ForgotPasswordRequestState({
    this.status = ForgotPasswordRequestStatus.idle,
    this.isEmailMode = true,
    this.emailError,
    this.phoneError,
    this.generalMessage,
    this.submittedEmail,
    this.submittedPhone,
  });

  final ForgotPasswordRequestStatus status;
  final bool isEmailMode;
  final String? emailError;
  final String? phoneError;
  final String? generalMessage;
  final String? submittedEmail;
  final String? submittedPhone;

  bool get isSubmitting => status == ForgotPasswordRequestStatus.submitting;

  ForgotPasswordRequestState copyWith({
    ForgotPasswordRequestStatus? status,
    bool? isEmailMode,
    String? emailError,
    bool clearEmailError = false,
    String? phoneError,
    bool clearPhoneError = false,
    String? generalMessage,
    bool clearGeneralMessage = false,
    String? submittedEmail,
    bool clearSubmittedEmail = false,
    String? submittedPhone,
    bool clearSubmittedPhone = false,
  }) {
    return ForgotPasswordRequestState(
      status: status ?? this.status,
      isEmailMode: isEmailMode ?? this.isEmailMode,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      generalMessage: clearGeneralMessage
          ? null
          : (generalMessage ?? this.generalMessage),
      submittedEmail: clearSubmittedEmail
          ? null
          : (submittedEmail ?? this.submittedEmail),
      submittedPhone: clearSubmittedPhone
          ? null
          : (submittedPhone ?? this.submittedPhone),
    );
  }
}
