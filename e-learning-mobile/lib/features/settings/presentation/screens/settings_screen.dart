import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedTheme = 'Sáng';
  String _selectedLanguage = 'Tiếng Việt';
  bool _isClearingCache = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Cài đặt ứng dụng',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 1. Account Section
          _buildSectionTitle(theme, 'Tài khoản & Bảo mật'),
          _buildSettingContainer([
            _buildSettingRow(
              icon: Icons.person_outline_rounded,
              title: 'Thông tin cá nhân',
              subtitle: 'Quản lý họ tên, email, số điện thoại',
              onTap: () => context.push('/app/profile/edit'),
            ),
            const Divider(height: 1),
            _buildSettingRow(
              icon: Icons.lock_outline_rounded,
              title: 'Đổi mật khẩu',
              subtitle: 'Cập nhật mật khẩu đăng nhập',
              onTap: () => context.push('/app/profile/change-password'),
            ),
            const Divider(height: 1),
            _buildSettingRow(
              icon: Icons.verified_user_outlined,
              title: 'Bảo mật & 2FA',
              subtitle: 'Xác thực hai yếu tố cho tài khoản',
              onTap: () => context.push('/app/profile/security'),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // 2. Preferences & System Configuration Section
          _buildSectionTitle(theme, 'Cấu hình ứng dụng'),
          _buildSettingContainer([
            SwitchListTile.adaptive(
              secondary: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
              title: const Text(
                'Thông báo nhắc nhở',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Bật/tắt lời nhắc nhở hằng ngày & khóa học',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              value: _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.palette_outlined,
                color: AppColors.textPrimary,
                size: 22,
              ),
              title: const Text(
                'Giao diện ứng dụng',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              trailing: DropdownButton<String>(
                value: _selectedTheme,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'Sáng',
                    child: Text('Sáng (Default)'),
                  ),
                  DropdownMenuItem(value: 'Tối', child: Text('Tối (Dark)')),
                  DropdownMenuItem(value: 'Hệ thống', child: Text('Tự động')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTheme = val);
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.language_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
              title: const Text(
                'Ngôn ngữ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'Tiếng Việt',
                    child: Text('Tiếng Việt'),
                  ),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // 3. Storage & Legal Section
          _buildSectionTitle(theme, 'Bộ nhớ & Pháp lý'),
          _buildSettingContainer([
            _buildSettingRow(
              icon: Icons.cleaning_services_outlined,
              title: 'Xóa bộ nhớ đệm (Cache)',
              subtitle: _isClearingCache
                  ? 'Đang dọn dẹp...'
                  : 'Giải phóng 120 MB dung lượng tạm',
              onTap: _clearCache,
            ),
            const Divider(height: 1),
            _buildSettingRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Quyền riêng tư & Dữ liệu',
              subtitle: 'Kiểm soát chia sẻ dữ liệu thể trạng',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dữ liệu thể trạng được mã hóa an toàn.'),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingRow(
              icon: Icons.description_outlined,
              title: 'Điều khoản sử dụng',
              onTap: () => _launchUrl('https://nhinanchualanh.vn/terms'),
            ),
            const Divider(height: 1),
            _buildSettingRow(
              icon: Icons.policy_outlined,
              title: 'Chính sách bảo mật',
              onTap: () => _launchUrl('https://nhinanchualanh.vn/privacy'),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // 4. Red Logout Row matching Screen 12
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22,
              ),
              title: const Text(
                'Đăng xuất tài khoản',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }

  void _clearCache() async {
    setState(() => _isClearingCache = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isClearingCache = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa 120 MB bộ nhớ đệm thành công!')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final refreshToken = ref
          .read(sessionControllerProvider)
          .session
          ?.refreshToken;
      try {
        await ref
            .read(authRepositoryProvider)
            .logout(LogoutRequest(refreshToken: refreshToken));
      } finally {
        await ref.read(sessionControllerProvider.notifier).clearSession();
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
