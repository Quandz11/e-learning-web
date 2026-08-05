enum VerifyOtpStatus { idle, submitting, success, failure }

class VerifyOtpState {
  const VerifyOtpState({
    this.status = VerifyOtpStatus.idle,
    this.otpError,
    this.generalMessage,
  });

  final VerifyOtpStatus status;
  final String? otpError;
  final String? generalMessage;

  bool get isSubmitting => status == VerifyOtpStatus.submitting;

  VerifyOtpState copyWith({
    VerifyOtpStatus? status,
    String? otpError,
    bool clearOtpError = false,
    String? generalMessage,
    bool clearGeneralMessage = false,
  }) {
    return VerifyOtpState(
      status: status ?? this.status,
      otpError: clearOtpError ? null : (otpError ?? this.otpError),
      generalMessage: clearGeneralMessage
          ? null
          : (generalMessage ?? this.generalMessage),
    );
  }
}
