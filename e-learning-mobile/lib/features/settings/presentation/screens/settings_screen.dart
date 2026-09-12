import 'package:e_learning_mobile/core/network/cache_service.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/services/home_widget_service.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/notifications/data/notifications_repository.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
import 'package:e_learning_mobile/shared/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _widgetSyncEnabled = true;
  String _selectedLanguage = 'Tiếng Việt';
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadWidgetSyncState();
  }

  Future<void> _loadWidgetSyncState() async {
    final enabled = await HomeWidgetService.instance.isSyncEnabled();
    if (mounted) {
      setState(() => _widgetSyncEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);
    final selectedTheme = themeNotifier.themeModeName;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
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
        title: Text(
          'Cài đặt ứng dụng',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: -0.3,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
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
                  color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.18) : const Color(0xFFFFFBEB),
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
                  color: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.18) : const Color(0xFFF5F3FF),
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
                value: selectedTheme,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'Sáng',
                    child: Text('Sáng (Light)'),
                  ),
                  DropdownMenuItem(value: 'Tối', child: Text('Tối (Dark)')),
                  DropdownMenuItem(value: 'Hệ thống', child: Text('Tự động (System)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    themeNotifier.setThemeModeByName(val);
                  }
                },
              ),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16A34A).withValues(alpha: 0.18) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Color(0xFF16A34A),
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
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            SwitchListTile.adaptive(
              secondary: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.18) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sync_outlined,
                  color: Color(0xFF0284C7),
                  size: 18,
                ),
              ),
              title: const Text(
                'Đồng bộ Widget di động',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              subtitle: const Text(
                'Tự động cập nhật dữ liệu ra màn hình khóa & chính',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w300),
              ),
              value: _widgetSyncEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                setState(() => _widgetSyncEnabled = val);
                await HomeWidgetService.instance.setSyncEnabled(val);
              },
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.widgets_outlined,
              title: 'Cấu hình mẫu Widget',
              subtitle: 'Chọn mẫu & xem trước Widget màn hình khóa/chính',
              bgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF0284C7),
              onTap: () => context.push('/app/settings/widgets'),
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
              onTap: () => context.push('${AppRoutes.appSettingsTermsPrivacy}?tab=privacy'),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.description_outlined,
              title: 'Điều khoản sử dụng',
              bgColor: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF64748B),
              onTap: () => context.push('${AppRoutes.appSettingsTermsPrivacy}?tab=terms'),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEAEFE9)),
            _buildSettingRow(
              icon: Icons.policy_outlined,
              title: 'Chính sách bảo mật',
              bgColor: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF64748B),
              onTap: () => context.push('${AppRoutes.appSettingsTermsPrivacy}?tab=privacy'),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // 4. Red Logout Row
          Container(
            decoration: BoxDecoration(
              color: context.cardBg(),
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
        color: context.cardBg(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.cardBorder(),
          width: 0.8,
        ),
        boxShadow: context.isDark
            ? null
            : [
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
    final isDark = context.isDark;
    final effectiveBgColor = isDark ? iconColor.withValues(alpha: 0.18) : bgColor;
    final effectiveIconColor = isDark ? (iconColor == AppColors.primary ? const Color(0xFF4CAF50) : iconColor) : iconColor;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: effectiveBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: context.textPrimary(),
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: context.textSecondary(),
                fontWeight: FontWeight.w300,
                fontSize: 12,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? context.colorScheme.onSurfaceVariant : const Color(0xFF9EABA3),
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
        try {
          await ref
              .read(notificationsRepositoryProvider)
              .unregisterCurrentDeviceToken();
        } catch (_) {}
        await ref
            .read(authRepositoryProvider)
            .logout(LogoutRequest(refreshToken: refreshToken));
      } finally {
        await ref.read(sessionControllerProvider.notifier).clearSession();
      }
    }
  }
}
