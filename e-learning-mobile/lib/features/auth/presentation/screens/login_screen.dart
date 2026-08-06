import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/login_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/login_state.dart';
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final redirectPath = _readRedirectPath(context);
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (previous?.status == next.status ||
          next.status != LoginStatus.twoFactorRequired) {
        return;
      }

      final challenge = next.pendingChallenge;
      if (challenge == null) {
        return;
      }

      ref
          .read(authOtpChallengeControllerProvider.notifier)
          .setChallenge(challenge);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.go(AppRoutes.verifyOtp, extra: challenge);
      });
    });

    return AppPage(
      appBarTitle: 'Đăng nhập',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Đăng nhập',
              subtitle: 'Sử dụng email và mật khẩu để tiếp tục.',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.generalMessage != null) ...[
              _LoginMessageCard(
                message: state.generalMessage!,
                isError: state.status != LoginStatus.twoFactorRequired,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              fieldKey: const Key('login_email_field'),
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              textInputAction: TextInputAction.next,
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onEmailChanged(),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              labelText: 'Email',
              hintText: 'name@example.com',
              errorText: state.emailError,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('login_password_field'),
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              enabled: !state.isSubmitting,
              onChanged: (_) => controller.onPasswordChanged(),
              onSubmitted: (_) =>
                  _submit(controller, redirectPath: redirectPath),
              labelText: 'Mật khẩu',
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
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('login_submit_button'),
              label: 'Đăng nhập',
              onPressed: () => _submit(controller, redirectPath: redirectPath),
              loading: state.isSubmitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              buttonKey: const Key('login_forgot_password_button'),
              label: 'Quên mật khẩu?',
              variant: AppButtonVariant.text,
              onPressed: state.isSubmitting
                  ? null
                  : () => context.go(AppRoutes.forgotPassword),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              buttonKey: const Key('login_to_register_button'),
              label: 'Chưa có tài khoản? Đăng ký',
              variant: AppButtonVariant.text,
              onPressed: state.isSubmitting
                  ? null
                  : () => context.go(AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }

  String? _readRedirectPath(BuildContext context) {
    try {
      return AppRoutes.safeAuthenticatedRedirect(
        GoRouterState.of(context).uri.queryParameters['from'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit(
    LoginController controller, {
    String? redirectPath,
  }) async {
    TextInput.finishAutofillContext();
    await controller.submit(
      email: _emailController.text,
      password: _passwordController.text,
      redirectPath: redirectPath,
    );
  }
}

class _LoginMessageCard extends StatelessWidget {
  const _LoginMessageCard({required this.message, required this.isError});

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
