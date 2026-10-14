import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_request_state.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/phone_number_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final forgotPasswordRequestControllerProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordRequestController,
      ForgotPasswordRequestState
    >((ref) {
      return ForgotPasswordRequestController(
        authRepository: ref.read(authRepositoryProvider),
      );
    });

class ForgotPasswordRequestController
    extends StateNotifier<ForgotPasswordRequestState> {
  ForgotPasswordRequestController({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const ForgotPasswordRequestState());

  final AuthRepository _authRepository;

  void setMode({required bool isEmailMode}) {
    if (state.isEmailMode == isEmailMode) return;
    state = ForgotPasswordRequestState(isEmailMode: isEmailMode);
  }

  Future<void> submit(String input) async {
    if (state.isSubmitting) {
      return;
    }

    if (state.isEmailMode) {
      final email = input.trim();
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (email.isEmpty) {
        state = state.copyWith(
          status: ForgotPasswordRequestStatus.failure,
          emailError: 'Vui lòng nhập địa chỉ email.',
        );
        return;
      }
      if (!emailRegex.hasMatch(email)) {
        state = state.copyWith(
          status: ForgotPasswordRequestStatus.failure,
          emailError: 'Địa chỉ email không hợp lệ.',
        );
        return;
      }

      state = state.copyWith(
        status: ForgotPasswordRequestStatus.submitting,
        clearEmailError: true,
        clearGeneralMessage: true,
      );

      try {
        final message = await _authRepository.requestEmailForgotPasswordOtp(
          email,
        );
        state = state.copyWith(
          status: ForgotPasswordRequestStatus.success,
          generalMessage: message,
          submittedEmail: email,
        );
      } on AppFailure catch (failure) {
        state = state.copyWith(
          status: ForgotPasswordRequestStatus.failure,
          generalMessage: failure.message,
        );
      }
    } else {
      final phoneError = validatePhoneInput(input);
      final normalizedPhone = normalizeVietnamesePhone(input);
      if (phoneError != null || normalizedPhone == null) {
        state = state.copyWith(
          status: ForgotPasswordRequestStatus.failure,
          phoneError: phoneError,
        );
        return;
      }

      state = state.copyWith(
        status: ForgotPasswordRequestStatus.submitting,
        clearPhoneError: true,
        clearGeneralMessage: true,
      );

      try {
        final message = await _authRepository.requestForgotPasswordOtp(
          normalizedPhone,
        );
        state = state.copyWith(
          status: ForgotPasswordRequestStatus.success,
          generalMessage: message,
          submittedPhone: normalizedPhone,
        );
      } on AppFailure catch (failure) {
        state = state.copyWith(
          status: ForgotPasswordRequestStatus.failure,
          generalMessage: failure.message,
        );
      }
    }
  }

  void onPhoneChanged() {
    onInputChanged();
  }

  void onInputChanged() {
    if (state.phoneError == null &&
        state.emailError == null &&
        state.generalMessage == null) {
      return;
    }

    state = state.copyWith(
      status: ForgotPasswordRequestStatus.idle,
      clearEmailError: true,
      clearPhoneError: true,
      clearGeneralMessage: true,
      clearSubmittedEmail: true,
      clearSubmittedPhone: true,
    );
  }
}
