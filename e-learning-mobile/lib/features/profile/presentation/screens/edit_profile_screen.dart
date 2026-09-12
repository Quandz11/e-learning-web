import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/edit_profile_state.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
import 'package:e_learning_mobile/shared/widgets/app_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  bool _initialized = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAvatarSourceSheet(Profile profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EBE5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn ảnh đại diện',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2621),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF0F5B38),
                    ),
                  ),
                  title: const Text('Chọn từ thư viện ảnh'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadAvatar(profile, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF0F5B38),
                    ),
                  ),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadAvatar(profile, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(Profile profile, ImageSource source) async {
    setState(() => _isUploadingAvatar = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked == null) {
        setState(() => _isUploadingAvatar = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      final url = await ref.read(profileRepositoryProvider).uploadAvatar(
        bytes: bytes,
        fileName: picked.name,
      );
      if (url.isNotEmpty && mounted) {
        final updated = profile.copyWith(avatarUrl: url);
        ref.read(profileControllerProvider.notifier).updateProfile(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện thành công!'),
            backgroundColor: Color(0xFF0F5B38),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        final msg = e.code == 'camera_access_denied' || e.code == 'photo_access_denied'
            ? 'Vui lòng cấp quyền truy cập máy ảnh hoặc thư viện trong cài đặt máy.'
            : 'Không thể mở thư viện/máy ảnh (${e.code}). Vui lòng kiểm tra quyền trên thiết bị.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
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

    return AppPage(
      appBarTitle: 'Chỉnh sửa hồ sơ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar Picker Pod
          Center(
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : () => _showAvatarSourceSheet(profile),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEAEFE9),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profile.avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: Color(0xFF0F5B38),
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: Color(0xFF0F5B38),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F5B38),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isUploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.cardBorder(),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: context.isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Địa chỉ Email (Không đổi)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: context.textMuted(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary(),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: context.textMuted(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            buttonKey: const Key('edit_profile_save_button'),
            label: 'Lưu thay đổi',
            onPressed: !state.isSubmitting
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật thông tin hồ sơ thành công.'),
        backgroundColor: Color(0xFF0F5B38),
      ),
    );
  }
}
