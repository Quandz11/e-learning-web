import 'package:e_learning_mobile/core/network/cache_service.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app/profile');
            }
          },
        ),
        title: const Text(
          'Cài đặt ứng dụng',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: -0.3,
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
              bgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              onTap: () => context.push('/app/profile/edit'),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.lock_outline_rounded,
              title: 'Đổi mật khẩu',
              subtitle: 'Cập nhật mật khẩu đăng nhập',
              bgColor: const Color(0xFFF5F3FF),
              iconColor: const Color(0xFF7C3AED),
              onTap: () => context.push('/app/profile/change-password'),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.verified_user_outlined,
              title: 'Bảo mật & 2FA',
              subtitle: 'Xác thực hai yếu tố cho tài khoản',
              bgColor: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF16A34A),
              onTap: () => context.push('/app/profile/security'),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // 2. Preferences & System Configuration Section
          _buildSectionTitle(theme, 'Cấu hình ứng dụng'),
          _buildSettingContainer([
            SwitchListTile.adaptive(
              secondary: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
              ),
              title: const Text(
                'Thông báo nhắc nhở',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              subtitle: const Text(
                'Bật/tắt lời nhắc nhở hằng ngày & khóa học',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w300),
              ),
              value: _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
              },
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: Color(0xFF7C3AED),
                  size: 18,
                ),
              ),
              title: const Text(
                'Giao diện ứng dụng',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Color(0xFF0F5B38),
                  size: 18,
                ),
              ),
              title: const Text(
                'Ngôn ngữ',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
                  : 'Xóa dữ liệu tải trước & bộ nhớ tạm',
              bgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFB45309),
              onTap: _clearCache,
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Quyền riêng tư & Dữ liệu',
              subtitle: 'Kiểm soát chia sẻ dữ liệu thể trạng',
              bgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dữ liệu thể trạng được mã hóa an toàn.'),
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.description_outlined,
              title: 'Điều khoản sử dụng',
              bgColor: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF64748B),
              onTap: () => _launchUrl('https://nhinanchualanh.vn/terms'),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.policy_outlined,
              title: 'Chính sách bảo mật',
              bgColor: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF64748B),
              onTap: () => _launchUrl('https://nhinanchualanh.vn/privacy'),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // 4. Red Logout Row matching Screen 12
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
              title: const Text(
                'Đăng xuất tài khoản',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.error,
                size: 20,
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
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildSettingContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEFE9),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color bgColor = const Color(0xFFF0F7F2),
    Color iconColor = AppColors.primary,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9EABA3),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _clearCache() async {
    setState(() => _isClearingCache = true);
    try {
      await ref.read(cacheServiceProvider).clear();
    } catch (_) {}
    if (mounted) {
      setState(() => _isClearingCache = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã dọn dẹp bộ nhớ đệm thành công!')),
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
