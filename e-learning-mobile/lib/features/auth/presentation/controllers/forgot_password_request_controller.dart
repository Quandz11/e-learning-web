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

  Future<void> submit(String phone) async {
    if (state.isSubmitting) {
      return;
    }

    final phoneError = validatePhoneInput(phone);
    final normalizedPhone = normalizeVietnamesePhone(phone);
    if (phoneError != null || normalizedPhone == null) {
      state = ForgotPasswordRequestState(
        status: ForgotPasswordRequestStatus.failure,
        phoneError: phoneError,
      );
      return;
    }

    state = const ForgotPasswordRequestState(
      status: ForgotPasswordRequestStatus.submitting,
    );

    try {
      final message = await _authRepository.requestForgotPasswordOtp(
        normalizedPhone,
      );
      state = ForgotPasswordRequestState(
        status: ForgotPasswordRequestStatus.success,
        generalMessage: message,
        submittedPhone: normalizedPhone,
      );
    } on AppFailure catch (failure) {
      state = ForgotPasswordRequestState(
        status: ForgotPasswordRequestStatus.failure,
        generalMessage: failure.message,
      );
    }
  }

  void onPhoneChanged() {
    if (state.phoneError == null && state.generalMessage == null) {
      return;
    }

    state = state.copyWith(
      status: ForgotPasswordRequestStatus.idle,
      clearPhoneError: true,
      clearGeneralMessage: true,
      clearSubmittedPhone: true,
    );
  }
}
