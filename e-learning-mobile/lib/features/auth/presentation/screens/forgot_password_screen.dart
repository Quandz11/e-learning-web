import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_request_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_request_state.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
import 'package:e_learning_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordRequestControllerProvider);
    final controller = ref.read(
      forgotPasswordRequestControllerProvider.notifier,
    );

    ref.listen<ForgotPasswordRequestState>(
      forgotPasswordRequestControllerProvider,
      (previous, next) {
        if (previous?.status == next.status ||
            next.status != ForgotPasswordRequestStatus.success) {
          return;
        }

        final challenge = next.isEmailMode
            ? ForgotPasswordChallenge(email: next.submittedEmail)
            : ForgotPasswordChallenge(phone: next.submittedPhone);

        if (!challenge.isValid) {
          return;
        }

        ref
            .read(forgotPasswordChallengeControllerProvider.notifier)
            .setChallenge(challenge);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          context.go(AppRoutes.forgotPasswordVerify, extra: challenge);
        });
      },
    );

    return AppPage(
      appBarTitle: 'Quên mật khẩu',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Khôi phục mật khẩu',
              subtitle: 'Chọn phương thức nhận mã OTP để đặt lại mật khẩu mới.',
            ),
            const SizedBox(height: AppSpacing.md),

            // Segmented Option Switcher (Email vs Phone)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2EBE5), width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMethodTab(
                      label: 'Email (Ưu tiên)',
                      icon: Icons.mail_outline_rounded,
                      isActive: state.isEmailMode,
                      onTap: () {
                        controller.setMode(isEmailMode: true);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildMethodTab(
                      label: 'Số điện thoại',
                      icon: Icons.phone_iphone_rounded,
                      isActive: !state.isEmailMode,
                      onTap: () {
                        controller.setMode(isEmailMode: false);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (state.generalMessage != null &&
                state.status == ForgotPasswordRequestStatus.failure) ...[
              _ForgotPasswordMessageCard(message: state.generalMessage!),
              const SizedBox(height: AppSpacing.md),
            ],

            if (state.isEmailMode)
              AppTextField(
                fieldKey: const Key('forgot_password_email_field'),
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                enabled: !state.isSubmitting,
                onChanged: (_) => controller.onInputChanged(),
                onSubmitted: (_) => _submit(controller),
                labelText: 'Địa chỉ Email',
                hintText: 'example@email.com',
                errorText: state.emailError,
                prefixIcon: const Icon(Icons.email_outlined),
              )
            else
              AppTextField(
                fieldKey: const Key('forgot_password_phone_field'),
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                enabled: !state.isSubmitting,
                onChanged: (_) => controller.onInputChanged(),
                onSubmitted: (_) => _submit(controller),
                labelText: 'Số điện thoại',
                hintText: '0912345678',
                errorText: state.phoneError,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),

            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('forgot_password_submit_button'),
              label: state.isEmailMode ? 'Gửi OTP qua Email' : 'Gửi OTP qua Zalo',
              onPressed: () => _submit(controller),
              loading: state.isSubmitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              buttonKey: const Key('forgot_password_back_to_login_button'),
              label: 'Quay lại đăng nhập',
              variant: AppButtonVariant.text,
              onPressed: state.isSubmitting
                  ? null
                  : () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF0F5B38) : const Color(0xFF717873),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF0F5B38) : const Color(0xFF717873),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(ForgotPasswordRequestController controller) async {
    TextInput.finishAutofillContext();
    final state = ref.read(forgotPasswordRequestControllerProvider);
    final input = state.isEmailMode
        ? _emailController.text
        : _phoneController.text;
    await controller.submit(input);
  }
}

class _ForgotPasswordMessageCard extends StatelessWidget {
  const _ForgotPasswordMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: AppCard(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
