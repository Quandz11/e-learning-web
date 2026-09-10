import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/security_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/security_state.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
import 'package:e_learning_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureDisablePassword = true;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.clear();
    _passwordController.dispose();
    ref.read(securityControllerProvider.notifier).clearSetup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).profile;
    final state = ref.watch(securityControllerProvider);
    final controller = ref.read(securityControllerProvider.notifier);
    final isEnabled = profile?.isTwoFactorEnabled ?? false;

    return AppPage(
      appBarTitle: 'Bảo mật',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Xác thực hai lớp',
            subtitle: isEnabled
                ? 'Tài khoản của bạn đang được bảo vệ bằng mã xác thực.'
                : 'Bật xác thực hai lớp để tăng cường bảo mật.',
          ),
          const SizedBox(height: AppSpacing.lg),
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
                    color: isEnabled
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEnabled
                        ? Icons.verified_user_rounded
                        : Icons.security_outlined,
                    color: isEnabled
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trạng thái bảo vệ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF8E9E94),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnabled ? 'Đang bật' : 'Đang tắt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF9EABA3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          if (state.generalMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(child: Text(state.generalMessage!)),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (!isEnabled) ...[
            AppButton(
              buttonKey: const Key('security_setup_button'),
              label: state.status == SecurityStatus.loadingSetup
                  ? 'Đang chuẩn bị...'
                  : 'Thiết lập 2FA',
              onPressed: state.isBusy ? null : controller.loadSetup,
            ),
            if (state.secret != null && state.qrCodeUri != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Quét mã QR bằng ứng dụng Authenticator',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2621),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9EBEA)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: state.qrCodeUri!,
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Hoặc nhập mã bí mật thủ công:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF717873),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      state.secret!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF0F5B38),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      buttonKey: const Key('security_copy_secret_button'),
                      label: 'Sao chép mã bí mật',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _copyValue(state.secret!),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      buttonKey: const Key('security_copy_qr_uri_button'),
                      label: 'Sao chép liên kết QR',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _copyValue(state.qrCodeUri!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const Key('security_enable_code_field'),
                controller: _codeController,
                labelText: 'Mã xác thực',
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                errorText: state.codeError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                buttonKey: const Key('security_enable_button'),
                label: 'Bật xác thực hai lớp',
                onPressed: state.isBusy ? null : () => _enable(controller),
                loading: state.status == SecurityStatus.enabling,
              ),
            ],
          ] else ...[
            AppTextField(
              fieldKey: const Key('security_disable_password_field'),
              controller: _passwordController,
              obscureText: _obscureDisablePassword,
              labelText: 'Mật khẩu hiện tại',
              errorText: state.passwordError,
              suffixIcon: IconButton(
                tooltip: _obscureDisablePassword
                    ? 'Hiện mật khẩu hiện tại'
                    : 'Ẩn mật khẩu hiện tại',
                onPressed: () {
                  setState(() {
                    _obscureDisablePassword = !_obscureDisablePassword;
                  });
                },
                icon: Icon(
                  _obscureDisablePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              buttonKey: const Key('security_disable_button'),
              label: 'Tắt xác thực hai lớp',
              variant: AppButtonVariant.destructive,
              onPressed: state.isBusy ? null : () => _disable(controller),
              loading: state.status == SecurityStatus.disabling,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyValue(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép.')));
  }

  Future<void> _enable(SecurityController controller) async {
    final success = await controller.enable(_codeController.text);
    if (!mounted || !success) {
      return;
    }
    _codeController.clear();
  }

  Future<void> _disable(SecurityController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tắt xác thực hai lớp'),
          content: const Text('Bạn có chắc chắn muốn tắt xác thực hai lớp?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final success = await controller.disable(_passwordController.text);
    if (!mounted || !success) {
      return;
    }
    _passwordController.clear();
  }
}
