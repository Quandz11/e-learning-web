enum ChangePasswordStatus { idle, submitting, success, failure }

class ChangePasswordState {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.currentPasswordError,
    this.newPasswordError,
    this.confirmPasswordError,
    this.generalMessage,
  });

  final ChangePasswordStatus status;
  final String? currentPasswordError;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final String? generalMessage;

  bool get isSubmitting => status == ChangePasswordStatus.submitting;
}
