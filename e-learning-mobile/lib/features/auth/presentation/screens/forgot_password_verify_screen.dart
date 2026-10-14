import 'dart:async';

import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_verify_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_verify_state.dart';
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

class ForgotPasswordVerifyScreen extends ConsumerStatefulWidget {
  const ForgotPasswordVerifyScreen({super.key, this.initialChallenge});

  final ForgotPasswordChallenge? initialChallenge;

  @override
  ConsumerState<ForgotPasswordVerifyScreen> createState() =>
      _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState
    extends ConsumerState<ForgotPasswordVerifyScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isResending = false;
  String? _resendMessage;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storedChallenge = ref.watch(
      forgotPasswordChallengeControllerProvider,
    );
    final challenge = storedChallenge ?? widget.initialChallenge;
    final state = ref.watch(forgotPasswordVerifyControllerProvider);
    final controller = ref.read(
      forgotPasswordVerifyControllerProvider.notifier,
    );

    if (storedChallenge == null && widget.initialChallenge?.isValid == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref
            .read(forgotPasswordChallengeControllerProvider.notifier)
            .setChallenge(widget.initialChallenge!);
      });
    }

    ref.listen<
      ForgotPasswordVerifyState
    >(forgotPasswordVerifyControllerProvider, (previous, next) {
      if (previous?.status == next.status ||
          next.status != ForgotPasswordVerifyStatus.success) {
        return;
      }

      ref.read(forgotPasswordChallengeControllerProvider.notifier).clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.generalMessage ??
                  'Đặt lại mật khẩu thành công. Vui lòng đăng nhập bằng mật khẩu mới.',
            ),
          ),
        );
        context.go(AppRoutes.login);
      });
    });

    if (challenge == null || !challenge.isValid) {
      return AppPage(
        appBarTitle: 'Đặt lại mật khẩu',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Không có phiên khôi phục',
              subtitle: 'Vui lòng bắt đầu lại quy trình quên mật khẩu.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('forgot_password_verify_back_button'),
              label: 'Quay lại',
              onPressed: () => context.go(AppRoutes.forgotPassword),
            ),
          ],
        ),
      );
    }

    return AppPage(
      appBarTitle: 'Đặt lại mật khẩu',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'Đặt lại mật khẩu',
              subtitle: challenge.isEmail
                  ? 'Nhập mã OTP được gửi về email của bạn và tạo mật khẩu mới.'
                  : 'Nhập mã OTP được gửi qua Zalo và tạo mật khẩu mới.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _RecipientCard(
              target: challenge.target,
              isEmail: challenge.isEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.generalMessage != null &&
                state.status == ForgotPasswordVerifyStatus.failure) ...[
              _StatusCard(message: state.generalMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_resendMessage != null) ...[
              _StatusCard(message: _resendMessage!, isError: false),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              fieldKey: const Key('forgot_password_verify_otp_field'),
              controller: _otpController,
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.oneTimeCode],
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onOtpChanged(),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              labelText: 'Mã OTP',
              hintText: '123456',
              errorText: state.otpError,
              prefixIcon: const Icon(Icons.password_outlined),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('forgot_password_verify_new_password_field'),
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onPasswordChanged(),
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
              labelText: 'Mật khẩu mới',
              errorText: state.passwordError,
              prefixIcon: const Icon(Icons.lock_outline),
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
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key(
                'forgot_password_verify_confirm_password_field',
              ),
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onConfirmPasswordChanged(),
              onSubmitted: (_) => _submit(controller, challenge),
              labelText: 'Xác nhận mật khẩu mới',
              errorText: state.confirmPasswordError,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Hiện xác nhận mật khẩu'
                    : 'Ẩn xác nhận mật khẩu',
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
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('forgot_password_verify_submit_button'),
              label: 'Xác nhận & Đặt lại mật khẩu',
              onPressed: () => _submit(controller, challenge),
              loading: state.isSubmitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              buttonKey: const Key('forgot_password_resend_button'),
              label: _cooldownSeconds > 0
                  ? 'Gửi lại OTP (${_cooldownSeconds}s)'
                  : 'Gửi lại OTP',
              variant: AppButtonVariant.text,
              onPressed:
                  _isResending || _cooldownSeconds > 0 || state.isSubmitting
                  ? null
                  : () => _resend(controller, challenge),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              buttonKey: const Key('forgot_password_cancel_button'),
              label: 'Quay lại đăng nhập',
              variant: AppButtonVariant.text,
              onPressed: state.isSubmitting ? null : _goBackToLogin,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    ForgotPasswordVerifyController controller,
    ForgotPasswordChallenge challenge,
  ) async {
    TextInput.finishAutofillContext();
    await controller.submit(
      phone: challenge.phone,
      email: challenge.email,
      otp: _otpController.text,
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  Future<void> _resend(
    ForgotPasswordVerifyController controller,
    ForgotPasswordChallenge challenge,
  ) async {
    setState(() {
      _isResending = true;
      _resendMessage = null;
    });

    final message = await controller.resend(
      phone: challenge.phone,
      email: challenge.email,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
      _resendMessage = message;
    });
    _startCooldown();
  }

  void _goBackToLogin() {
    ref.read(forgotPasswordChallengeControllerProvider.notifier).clear();
    context.go(AppRoutes.login);
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownSeconds = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _cooldownSeconds = 0;
          });
        }
        return;
      }
      setState(() {
        _cooldownSeconds -= 1;
      });
    });
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.target, required this.isEmail});

  final String target;
  final bool isEmail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            isEmail ? Icons.email_outlined : Icons.phone_android_outlined,
            color: const Color(0xFF0F5B38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              target,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isError ? colorScheme.error : colorScheme.primary;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    return Semantics(
      liveRegion: true,
      child: AppCard(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.info_outline,
                  color: foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: TextStyle(color: foreground)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
