import 'package:go_router/go_router.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/security_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/security_state.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
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
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.cardBg(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.cardBorder(),
                width: 0.8,
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: Color(0xFFEA580C),
                  size: 18,
                ),
              ),
              title: const Text(
                'Thiết bị đăng nhập',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              subtitle: Text(
                'Xem và quản lý các phiên đăng nhập đang hoạt động',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: context.textSecondary(),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.textMuted(),
              ),
              onTap: () => context.push('/app/profile/security/devices'),
            ),
          ),
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
                    color: isEnabled
                        ? (context.isDark ? const Color(0xFF143823) : const Color(0xFFF0FDF4))
                        : (context.isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEnabled
                        ? Icons.verified_user_rounded
                        : Icons.security_outlined,
                    color: isEnabled
                        ? const Color(0xFF16A34A)
                        : context.textSecondary(),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái bảo vệ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: context.textMuted(),
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
                              : context.textSecondary(),
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
                        : context.textMuted(),
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
                    Text(
                      'Quét mã QR bằng ứng dụng Authenticator',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary(),
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
                          border: Border.all(color: context.cardBorder()),
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
                    Text(
                      'Hoặc nhập mã bí mật thủ công:',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary(),
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
          const SizedBox(height: AppSpacing.xl),
          const AppSectionHeader(
            title: 'Xóa tài khoản',
            subtitle: 'Xóa vĩnh viễn tài khoản và toàn bộ dữ liệu học tập của bạn.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vùng nguy hiểm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sau khi xóa, tất cả tiến trình học tập, thông tin cá nhân và dữ liệu nhịn ăn của bạn sẽ bị xóa vĩnh viễn và không thể phục hồi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary(),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  buttonKey: const Key('security_delete_account_button'),
                  label: 'Xóa tài khoản vĩnh viễn',
                  variant: AppButtonVariant.destructive,
                  onPressed: () => _confirmDeleteAccount(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài khoản'),
        content: const Text(
          'Bạn có CHẮC CHẮN muốn xóa vĩnh viễn tài khoản này không?\n\n'
          'Tất cả dữ liệu hồ sơ, kết quả học tập và nhật ký nhịn ăn sẽ bị xóa hoàn toàn khỏi hệ thống và KHÔNG THỂ KHÔI PHỤC.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      await ref.read(sessionControllerProvider.notifier).clearSession();
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Không thể xóa tài khoản: $e')),
        );
      }
    }
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
