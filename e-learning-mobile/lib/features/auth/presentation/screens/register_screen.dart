import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/register_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/register_state.dart';
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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralCodeController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _referralCodeFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _referralCodeController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _referralCodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);

    ref.listen<RegisterState>(registerControllerProvider, (previous, next) {
      if (previous?.status == next.status ||
          next.status != RegisterStatus.success) {
        return;
      }

      final submittedEmail = next.submittedEmail;
      if (submittedEmail == null || submittedEmail.trim().isEmpty) {
        return;
      }

      final challenge = AuthOtpChallenge.registration(
        email: submittedEmail,
        displayMessage: next.generalMessage,
      );
      ref
          .read(authOtpChallengeControllerProvider.notifier)
          .setChallenge(challenge);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final verifyOtpUri = Uri(
          path: AppRoutes.verifyOtp,
          queryParameters: <String, String>{
            'type': 'registration',
            'email': challenge.email,
          },
        );
        context.go(verifyOtpUri.toString(), extra: challenge);
      });
    });

    return AppPage(
      appBarTitle: 'Register',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Create account',
              subtitle:
                  'Register with your email to receive a verification code.',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.generalMessage != null &&
                state.status == RegisterStatus.failure) ...[
              _RegisterMessageCard(message: state.generalMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              fieldKey: const Key('register_full_name_field'),
              controller: _fullNameController,
              focusNode: _fullNameFocusNode,
              textInputAction: TextInputAction.next,
              enabled: !state.isSubmitting,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => controller.onFullNameChanged(),
              onSubmitted: (_) => _emailFocusNode.requestFocus(),
              labelText: 'Full name',
              errorText: state.fullNameError,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('register_email_field'),
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !state.isSubmitting,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              onChanged: (_) => controller.onEmailChanged(),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              labelText: 'Email',
              hintText: 'name@example.com',
              errorText: state.emailError,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('register_password_field'),
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !state.isSubmitting,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => controller.onPasswordChanged(),
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
              labelText: 'Password',
              errorText: state.passwordError,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('register_confirm_password_field'),
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.next,
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onConfirmPasswordChanged(),
              onSubmitted: (_) => _phoneFocusNode.requestFocus(),
              labelText: 'Confirm password',
              errorText: state.confirmPasswordError,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Show confirm password'
                    : 'Hide confirm password',
                onPressed: state.isSubmitting
                    ? null
                    : () {
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
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('register_phone_field'),
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !state.isSubmitting,
              autofillHints: const [AutofillHints.telephoneNumber],
              onChanged: (_) => controller.onPhoneChanged(),
              onSubmitted: (_) => _referralCodeFocusNode.requestFocus(),
              labelText: 'Phone (optional)',
              errorText: state.phoneError,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('register_referral_code_field'),
              controller: _referralCodeController,
              focusNode: _referralCodeFocusNode,
              textInputAction: TextInputAction.done,
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onReferralCodeChanged(),
              onSubmitted: (_) => _submit(controller),
              labelText: 'Referral code (optional)',
              errorText: state.referralCodeError,
              prefixIcon: const Icon(Icons.sell_outlined),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('register_submit_button'),
              label: 'Create account',
              onPressed: () => _submit(controller),
              loading: state.isSubmitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              buttonKey: const Key('register_to_login_button'),
              label: 'Already have an account? Sign in',
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

  Future<void> _submit(RegisterController controller) async {
    TextInput.finishAutofillContext();
    await controller.submit(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      phone: _phoneController.text,
      referralCode: _referralCodeController.text,
    );
  }
}

class _RegisterMessageCard extends StatelessWidget {
  const _RegisterMessageCard({required this.message});

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
