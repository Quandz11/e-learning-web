import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/edit_profile_state.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
import 'package:e_learning_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final state = ref.watch(editProfileControllerProvider);
    final controller = ref.read(editProfileControllerProvider.notifier);

    if (!_initialized && profileState.profile != null) {
      _fillFromProfile(profileState.profile!);
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.markReady();
      });
    }

    if (profileState.profile == null &&
        profileState.status == ProfileStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileControllerProvider.notifier).load();
      });
    }

    final profile = profileState.profile;
    if (profile == null) {
      return const AppPage(
        appBarTitle: 'Chỉnh sửa hồ sơ',
        child: AppLoadingView(label: 'Đang tải hồ sơ...'),
      );
    }

    final hasChanges =
        _fullNameController.text.trim() != profile.fullName ||
        _phoneController.text.trim() != (profile.phone ?? '');

    return AppPage(
      appBarTitle: 'Chỉnh sửa hồ sơ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Chỉnh sửa hồ sơ',
            subtitle: 'Bạn chỉ có thể cập nhật họ tên và số điện thoại.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.generalMessage != null &&
              state.status == EditProfileStatus.failure) ...[
            AppCard(child: Text(state.generalMessage!)),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            fieldKey: const Key('edit_profile_full_name_field'),
            controller: _fullNameController,
            labelText: 'Họ tên',
            textInputAction: TextInputAction.next,
            enabled: !state.isSubmitting,
            errorText: state.fullNameError,
            onChanged: (_) => controller.onFullNameChanged(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('edit_profile_phone_field'),
            controller: _phoneController,
            labelText: 'Số điện thoại',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            enabled: !state.isSubmitting,
            errorText: state.phoneError,
            onChanged: (_) => controller.onPhoneChanged(),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEAEFE9),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Địa chỉ Email (Không đổi)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF8E9E94),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A2520),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFF9EABA3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            buttonKey: const Key('edit_profile_save_button'),
            label: 'Lưu thay đổi',
            onPressed: hasChanges && !state.isSubmitting
                ? () => _submit(controller, profile)
                : null,
            loading: state.isSubmitting,
          ),
        ],
      ),
    );
  }

  void _fillFromProfile(Profile profile) {
    _fullNameController.text = profile.fullName;
    _phoneController.text = profile.phone ?? '';
  }

  Future<void> _submit(
    EditProfileController controller,
    Profile profile,
  ) async {
    TextInput.finishAutofillContext();
    final updated = await controller.submit(
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      avatarUrl: profile.avatarUrl,
    );
    if (!mounted || updated == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));
  }
}
