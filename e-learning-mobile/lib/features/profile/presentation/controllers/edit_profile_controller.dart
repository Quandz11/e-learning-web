import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/models/update_profile_request.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/edit_profile_state.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final editProfileControllerProvider =
    StateNotifierProvider.autoDispose<EditProfileController, EditProfileState>((
      ref,
    ) {
      return EditProfileController(
        repository: ref.read(profileRepositoryProvider),
        profileController: ref.read(profileControllerProvider.notifier),
      );
    });

class EditProfileController extends StateNotifier<EditProfileState> {
  EditProfileController({
    required ProfileRepository repository,
    required ProfileController profileController,
  }) : _repository = repository,
       _profileController = profileController,
       super(const EditProfileState());

  final ProfileRepository _repository;
  final ProfileController _profileController;

  void markReady() {
    if (state.status == EditProfileStatus.loading) {
      state = const EditProfileState(status: EditProfileStatus.ready);
    }
  }

  void onFullNameChanged() {
    if (state.fullNameError == null && state.generalMessage == null) {
      return;
    }
    state = state.copyWith(
      status: EditProfileStatus.ready,
      clearFullNameError: true,
      clearGeneralMessage: true,
    );
  }

  void onPhoneChanged() {
    if (state.phoneError == null && state.generalMessage == null) {
      return;
    }
    state = state.copyWith(
      status: EditProfileStatus.ready,
      clearPhoneError: true,
      clearGeneralMessage: true,
    );
  }

  Future<Profile?> submit({
    required String fullName,
    required String phone,
    required String? avatarUrl,
  }) async {
    if (state.isSubmitting) {
      return null;
    }

    final normalizedFullName = fullName.trim();
    final normalizedPhone = phone.trim();

    final fullNameError = normalizedFullName.isEmpty
        ? 'Vui lòng nhập họ tên.'
        : null;
    final phoneError =
        normalizedPhone.isNotEmpty &&
            !RegExp(r'^\d{9,15}$').hasMatch(normalizedPhone)
        ? 'Số điện thoại không hợp lệ.'
        : null;

    if (fullNameError != null || phoneError != null) {
      state = EditProfileState(
        status: EditProfileStatus.failure,
        fullNameError: fullNameError,
        phoneError: phoneError,
      );
      return null;
    }

    state = const EditProfileState(status: EditProfileStatus.submitting);

    try {
      final profile = await _repository.updateProfile(
        UpdateProfileRequest(
          fullName: normalizedFullName,
          phone: normalizedPhone.isEmpty ? null : normalizedPhone,
          avatarUrl: avatarUrl,
        ),
      );
      _profileController.updateProfile(profile);
      state = const EditProfileState(status: EditProfileStatus.success);
      return profile;
    } on AppFailure catch (failure) {
      final validation = failure.validationErrors ?? const {};
      state = EditProfileState(
        status: EditProfileStatus.failure,
        fullNameError: validation['fullName']?.join(' '),
        phoneError: validation['phone']?.join(' '),
        generalMessage: failure.message,
      );
      return null;
    }
  }
}
