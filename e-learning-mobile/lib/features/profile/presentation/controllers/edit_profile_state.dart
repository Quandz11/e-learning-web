enum EditProfileStatus { loading, ready, submitting, success, failure }

class EditProfileState {
  const EditProfileState({
    this.status = EditProfileStatus.loading,
    this.fullNameError,
    this.phoneError,
    this.generalMessage,
  });

  final EditProfileStatus status;
  final String? fullNameError;
  final String? phoneError;
  final String? generalMessage;

  bool get isSubmitting => status == EditProfileStatus.submitting;

  EditProfileState copyWith({
    EditProfileStatus? status,
    String? fullNameError,
    bool clearFullNameError = false,
    String? phoneError,
    bool clearPhoneError = false,
    String? generalMessage,
    bool clearGeneralMessage = false,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      fullNameError: clearFullNameError
          ? null
          : (fullNameError ?? this.fullNameError),
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      generalMessage: clearGeneralMessage
          ? null
          : (generalMessage ?? this.generalMessage),
    );
  }
}
