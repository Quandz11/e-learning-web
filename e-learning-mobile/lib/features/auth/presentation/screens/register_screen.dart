import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/register_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/register_state.dart';
import 'package:e_learning_mobile/features/auth/presentation/widgets/auth_surface.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
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
  bool _acceptedTerms = true;

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

    return AuthSurface(
      leading: AuthBackButton(
        onPressed: state.isSubmitting
            ? null
            : () => context.go(AppRoutes.login),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          AuthFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeading(
                  title: 'Đăng ký tài khoản',
                  subtitle:
                      'Bắt đầu hành trình nhịn ăn và sống khỏe mạnh cùng chúng tôi!',
                  centered: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.generalMessage != null &&
                    state.status == RegisterStatus.failure) ...[
                  AuthMessageCard(message: state.generalMessage!),
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
                  labelText: 'Họ và tên',
                  hintText: 'Nhập họ và tên',
                  errorText: state.fullNameError,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
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
                  onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                  labelText: 'Email',
                  hintText: 'Nhập email của bạn',
                  errorText: state.emailError,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
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
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  labelText: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại',
                  errorText: state.phoneError,
                  prefixIcon: const Icon(Icons.phone_outlined),
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
                  labelText: 'Mật khẩu',
                  hintText: 'Tạo mật khẩu',
                  errorText: state.passwordError,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
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
                  onSubmitted: (_) => _referralCodeFocusNode.requestFocus(),
                  labelText: 'Xác nhận mật khẩu',
                  hintText: 'Nhập lại mật khẩu',
                  errorText: state.confirmPasswordError,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmPassword
                        ? 'Hiện xác nhận mật khẩu'
                        : 'Ẩn xác nhận mật khẩu',
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
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
                  labelText: 'Mã giới thiệu (không bắt buộc)',
                  hintText: 'Nhập mã giới thiệu',
                  errorText: state.referralCodeError,
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  container: true,
                  label: 'Đồng ý điều khoản sử dụng và chính sách bảo mật',
                  child: Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                    key: const Key('register_terms_checkbox'),
                    value: _acceptedTerms,
                    onChanged: state.isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    title: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: 'Tôi đồng ý với '),
                          TextSpan(
                            text: 'Điều khoản sử dụng',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' và '),
                          TextSpan(
                            text: 'Chính sách bảo mật',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  button: true,
                  enabled: !state.isSubmitting,
                  label: state.isSubmitting ? 'Đang đăng ký' : 'Đăng ký',
                  child: AppButton(
                    buttonKey: const Key('register_submit_button'),
                    label: 'Đăng ký',
                    onPressed: () => _submit(controller),
                    loading: state.isSubmitting,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthFooterPrompt(
            prompt: 'Đã có tài khoản?',
            actionLabel: 'Đăng nhập',
            buttonKey: const Key('register_to_login_button'),
            onPressed: state.isSubmitting
                ? null
                : () => context.go(AppRoutes.login),
          ),
        ],
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
