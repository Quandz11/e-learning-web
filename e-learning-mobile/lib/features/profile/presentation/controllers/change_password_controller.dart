import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/profile/data/models/change_password_request.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/change_password_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final changePasswordControllerProvider =
    StateNotifierProvider.autoDispose<
      ChangePasswordController,
      ChangePasswordState
    >((ref) {
      return ChangePasswordController(ref.read(profileRepositoryProvider));
    });

class ChangePasswordController extends StateNotifier<ChangePasswordState> {
  ChangePasswordController(this._repository)
    : super(const ChangePasswordState());

  final ProfileRepository _repository;

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    final currentPasswordError = currentPassword.isEmpty
        ? 'Vui lòng nhập mật khẩu hiện tại.'
        : null;
    final newPasswordError = newPassword.isEmpty
        ? 'Vui lòng nhập mật khẩu mới.'
        : newPassword.length < 8
        ? 'Mật khẩu mới phải có ít nhất 8 ký tự.'
        : null;
    final confirmPasswordError = confirmPassword.isEmpty
        ? 'Vui lòng xác nhận mật khẩu mới.'
        : confirmPassword != newPassword
        ? 'Mật khẩu xác nhận không khớp.'
        : null;

    if (currentPasswordError != null ||
        newPasswordError != null ||
        confirmPasswordError != null) {
      state = ChangePasswordState(
        status: ChangePasswordStatus.failure,
        currentPasswordError: currentPasswordError,
        newPasswordError: newPasswordError,
        confirmPasswordError: confirmPasswordError,
      );
      return false;
    }

    state = const ChangePasswordState(status: ChangePasswordStatus.submitting);
    try {
      await _repository.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      state = const ChangePasswordState(
        status: ChangePasswordStatus.success,
        generalMessage: 'Đổi mật khẩu thành công.',
      );
      return true;
    } on AppFailure catch (failure) {
      final validation = failure.validationErrors ?? const {};
      state = ChangePasswordState(
        status: ChangePasswordStatus.failure,
        currentPasswordError: validation['currentPassword']?.join(' '),
        newPasswordError: validation['newPassword']?.join(' '),
        generalMessage: failure.message,
      );
      return false;
    }
  }
}
