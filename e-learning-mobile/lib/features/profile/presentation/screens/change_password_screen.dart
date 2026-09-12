import 'package:e_learning_mobile/features/profile/presentation/controllers/change_password_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/change_password_state.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);
    final controller = ref.read(changePasswordControllerProvider.notifier);

    return AppPage(
      appBarTitle: 'Đổi mật khẩu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    color: context.isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                          color: context.textPrimary(),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Mật khẩu mới phải có ít nhất 8 ký tự.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: context.textSecondary(),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.generalMessage != null &&
              state.status == ChangePasswordStatus.failure) ...[
            AppCard(child: Text(state.generalMessage!)),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            fieldKey: const Key('change_password_current_field'),
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            labelText: 'Mật khẩu hiện tại',
            autofillHints: const [AutofillHints.password],
            errorText: state.currentPasswordError,
            suffixIcon: IconButton(
              tooltip: _obscureCurrentPassword
                  ? 'Hiện mật khẩu hiện tại'
                  : 'Ẩn mật khẩu hiện tại',
              onPressed: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
              icon: Icon(
                _obscureCurrentPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('change_password_new_field'),
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            labelText: 'Mật khẩu mới',
            autofillHints: const [AutofillHints.newPassword],
            errorText: state.newPasswordError,
            suffixIcon: IconButton(
              tooltip: _obscureNewPassword
                  ? 'Hiện mật khẩu mới'
                  : 'Ẩn mật khẩu mới',
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('change_password_confirm_field'),
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            labelText: 'Xác nhận mật khẩu mới',
            errorText: state.confirmPasswordError,
            suffixIcon: IconButton(
              tooltip: _obscureConfirmPassword
                  ? 'Hiện xác nhận mật khẩu'
                  : 'Ẩn xác nhận mật khẩu',
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            buttonKey: const Key('change_password_submit_button'),
            label: 'Cập nhật mật khẩu',
            onPressed: () => _submit(controller),
            loading: state.isSubmitting,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(ChangePasswordController controller) async {
    TextInput.finishAutofillContext();
    final success = await controller.submit(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted || !success) {
      return;
    }

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công.')));
  }
}
