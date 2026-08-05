import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/verify_otp_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/verify_otp_state.dart';
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

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, this.initialChallenge});

  final AuthOtpChallenge? initialChallenge;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storedChallenge = ref.watch(authOtpChallengeControllerProvider);
    final challenge = storedChallenge ?? widget.initialChallenge;
    final state = ref.watch(verifyOtpControllerProvider);
    final controller = ref.read(verifyOtpControllerProvider.notifier);

    if (storedChallenge == null && widget.initialChallenge?.isValid == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref
            .read(authOtpChallengeControllerProvider.notifier)
            .setChallenge(widget.initialChallenge!);
      });
    }

    ref.listen<VerifyOtpState>(verifyOtpControllerProvider, (previous, next) {
      if (previous?.status == next.status ||
          next.status != VerifyOtpStatus.success) {
        return;
      }
      context.go(AppRoutes.appHome);
    });

    if (challenge == null || !challenge.isValid) {
      return AppPage(
        appBarTitle: 'Verify code',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Verification required',
              subtitle:
                  'Your verification session is no longer available. Sign in to continue.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('otp_missing_back_to_login_button'),
              label: 'Back to login',
              onPressed: _goToLogin,
            ),
          ],
        ),
      );
    }

    return AppPage(
      appBarTitle: 'Verify code',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: challenge.type == AuthOtpChallengeType.registration
                  ? 'Verify your account'
                  : 'Complete sign in',
              subtitle: challenge.displayMessage?.trim().isNotEmpty ?? false
                  ? challenge.displayMessage!
                  : challenge.type == AuthOtpChallengeType.registration
                  ? 'Enter the 6-digit code sent to your email address.'
                  : 'Enter the 6-digit code from your authenticator app.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _OtpEmailCard(maskedEmail: _maskEmail(challenge.email)),
            const SizedBox(height: AppSpacing.md),
            if (state.generalMessage != null &&
                state.status == VerifyOtpStatus.failure) ...[
              _OtpMessageCard(message: state.generalMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              fieldKey: const Key('otp_code_field'),
              controller: _otpController,
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onOtpChanged(),
              onSubmitted: (_) => _submit(controller, challenge),
              labelText: 'Verification code',
              hintText: '123456',
              errorText: state.otpError,
              prefixIcon: const Icon(Icons.password_outlined),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('otp_submit_button'),
              label: 'Verify code',
              onPressed: () => _submit(controller, challenge),
              loading: state.isSubmitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              buttonKey: const Key('otp_back_to_login_button'),
              label: 'Back to login',
              variant: AppButtonVariant.text,
              onPressed: state.isSubmitting ? null : _goToLogin,
            ),
          ],
        ),
      ),
    );
  }

  void _goToLogin() {
    ref.read(authOtpChallengeControllerProvider.notifier).clear();
    context.go(AppRoutes.login);
  }

  Future<void> _submit(
    VerifyOtpController controller,
    AuthOtpChallenge challenge,
  ) {
    TextInput.finishAutofillContext();
    return controller.submit(challenge: challenge, otp: _otpController.text);
  }

  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 1 || atIndex == email.length - 1) {
      return email;
    }

    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    final visible = local.length <= 2 ? 1 : 2;
    final maskedLength = local.length - visible;
    return '${local.substring(0, visible)}${'*' * maskedLength}$domain';
  }
}

class _OtpEmailCard extends StatelessWidget {
  const _OtpEmailCard({required this.maskedEmail});

  final String maskedEmail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Semantics(
        label: 'Verification destination $maskedEmail',
        child: Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                maskedEmail,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpMessageCard extends StatelessWidget {
  const _OtpMessageCard({required this.message});

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
