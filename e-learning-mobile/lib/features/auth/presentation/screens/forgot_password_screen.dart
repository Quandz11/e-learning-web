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
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  @override
  void dispose() {
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

        final submittedPhone = next.submittedPhone;
        if (submittedPhone == null || submittedPhone.isEmpty) {
          return;
        }

        final challenge = ForgotPasswordChallenge(phone: submittedPhone);
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
              subtitle: 'Nhập số điện thoại để nhận mã OTP qua Zalo.',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.generalMessage != null &&
                state.status == ForgotPasswordRequestStatus.failure) ...[
              _ForgotPasswordMessageCard(message: state.generalMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              fieldKey: const Key('forgot_password_phone_field'),
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onPhoneChanged(),
              onSubmitted: (_) => _submit(controller),
              labelText: 'Số điện thoại',
              hintText: '0912345678',
              errorText: state.phoneError,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('forgot_password_submit_button'),
              label: 'Gửi mã OTP',
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

  Future<void> _submit(ForgotPasswordRequestController controller) async {
    TextInput.finishAutofillContext();
    await controller.submit(_phoneController.text);
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
