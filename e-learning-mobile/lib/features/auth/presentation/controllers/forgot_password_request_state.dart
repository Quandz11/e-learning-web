enum ForgotPasswordRequestStatus { idle, submitting, success, failure }

class ForgotPasswordRequestState {
  const ForgotPasswordRequestState({
    this.status = ForgotPasswordRequestStatus.idle,
    this.phoneError,
    this.generalMessage,
    this.submittedPhone,
  });

  final ForgotPasswordRequestStatus status;
  final String? phoneError;
  final String? generalMessage;
  final String? submittedPhone;

  bool get isSubmitting => status == ForgotPasswordRequestStatus.submitting;

  ForgotPasswordRequestState copyWith({
    ForgotPasswordRequestStatus? status,
    String? phoneError,
    bool clearPhoneError = false,
    String? generalMessage,
    bool clearGeneralMessage = false,
    String? submittedPhone,
    bool clearSubmittedPhone = false,
  }) {
    return ForgotPasswordRequestState(
      status: status ?? this.status,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      generalMessage: clearGeneralMessage
          ? null
          : (generalMessage ?? this.generalMessage),
      submittedPhone: clearSubmittedPhone
          ? null
          : (submittedPhone ?? this.submittedPhone),
    );
  }
}
