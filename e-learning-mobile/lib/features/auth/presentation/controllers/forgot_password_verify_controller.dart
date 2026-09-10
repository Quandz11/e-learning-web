import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_verify_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final forgotPasswordVerifyControllerProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordVerifyController,
      ForgotPasswordVerifyState
    >((ref) {
      return ForgotPasswordVerifyController(
        authRepository: ref.read(authRepositoryProvider),
      );
    });

class ForgotPasswordVerifyController
    extends StateNotifier<ForgotPasswordVerifyState> {
  ForgotPasswordVerifyController({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const ForgotPasswordVerifyState());

  final AuthRepository _authRepository;

  Future<void> submit({
    String? phone,
    String? email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    final normalizedOtp = otp.trim();
    final otpError = _validateOtp(normalizedOtp);
    final passwordError = _validatePassword(newPassword);
    final confirmPasswordError = _validateConfirmPassword(
      newPassword,
      confirmPassword,
    );

    if (otpError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      state = ForgotPasswordVerifyState(
        status: ForgotPasswordVerifyStatus.failure,
        otpError: otpError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
      );
      return;
    }

    state = const ForgotPasswordVerifyState(
      status: ForgotPasswordVerifyStatus.submitting,
    );

    try {
      final message = email != null && email.isNotEmpty
          ? await _authRepository.verifyEmailForgotPasswordOtp(
              email: email,
              otp: normalizedOtp,
              newPassword: newPassword,
            )
          : await _authRepository.verifyForgotPasswordOtp(
              phone: phone ?? '',
              otp: normalizedOtp,
              newPassword: newPassword,
            );
      state = ForgotPasswordVerifyState(
        status: ForgotPasswordVerifyStatus.success,
        generalMessage: message,
      );
    } on AppFailure catch (failure) {
      state = ForgotPasswordVerifyState(
        status: ForgotPasswordVerifyStatus.failure,
        generalMessage: failure.message,
      );
    }
  }

  Future<String?> resend({String? phone, String? email}) async {
    try {
      if (email != null && email.isNotEmpty) {
        return await _authRepository.resendEmailForgotPasswordOtp(email);
      } else {
        return await _authRepository.resendForgotPasswordOtp(phone ?? '');
      }
    } on AppFailure catch (failure) {
      return failure.message;
    }
  }

  void onOtpChanged() => _clear(clearOtpError: true);

  void onPasswordChanged() => _clear(clearPasswordError: true);

  void onConfirmPasswordChanged() => _clear(clearConfirmPasswordError: true);

  void _clear({
    bool clearOtpError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
  }) {
    if (state.otpError == null &&
        state.passwordError == null &&
        state.confirmPasswordError == null &&
        state.generalMessage == null) {
      return;
    }

    state = state.copyWith(
      status: ForgotPasswordVerifyStatus.idle,
      clearOtpError: clearOtpError,
      clearPasswordError: clearPasswordError,
      clearConfirmPasswordError: clearConfirmPasswordError,
      clearGeneralMessage: true,
    );
  }

  String? _validateOtp(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mã OTP.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Mã OTP phải gồm 6 chữ số.';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới.';
    }
    if (value.trim().length < 8) {
      return 'Mật khẩu mới phải có ít nhất 8 ký tự.';
    }
    return null;
  }

  String? _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới.';
    }
    if (password != confirmPassword) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }
}
