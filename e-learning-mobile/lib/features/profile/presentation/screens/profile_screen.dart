import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_avatar.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Làm mới hồ sơ',
            onPressed: () => controller.refresh(),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isLoading) ...[
                const AppLoadingView(label: 'Đang tải hồ sơ...'),
              ] else if (state.status == ProfileStatus.failure &&
                  state.profile == null) ...[
                AppErrorView(
                  message: state.message ?? 'Không thể tải hồ sơ.',
                  onRetry: controller.load,
                ),
              ] else ...[
                // 1. Profile Header Card matching Screen 11
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: state.profile?.fullName ?? 'Mai Dung',
                        imageUrl: state.profile?.avatarUrl,
                        size: 64,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.profile?.fullName ?? 'Mai Dung',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.profile?.email ?? 'maidung@gmail.com',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Thành viên Kim Cương 💎',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. 6 Option Menu Cards matching Screen 11
                _buildMenuOption(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Hồ sơ của tôi',
                  subtitle: 'Cập nhật thông tin cá nhân & ảnh đại diện',
                  onTap: () => context.push(AppRoutes.appProfileEdit),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildMenuOption(
                  context,
                  icon: Icons.emoji_events_outlined,
                  title: 'Thành tích & Huy hiệu',
                  subtitle: 'Đã đạt 5 huy hiệu bài học & chuỗi 7 ngày',
                  onTap: () => _showAchievementsDialog(context),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildMenuOption(
                  context,
                  icon: Icons.history_edu_rounded,
                  title: 'Lịch sử học tập',
                  subtitle: 'Xem danh sách bài đã xem & tiến độ tích lũy',
                  onTap: () => context.push(AppRoutes.appProgress),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildMenuOption(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt ứng dụng',
                  subtitle: 'Thông báo, bảo mật & bộ nhớ đệm',
                  onTap: () => context.push(AppRoutes.appSettings),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildMenuOption(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Trung tâm trợ giúp',
                  subtitle: 'Hỏi đáp bác sĩ & hỗ trợ kỹ thuật',
                  onTap: () => _showSupportDialog(context),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildMenuOption(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'Về ứng dụng Nhìn Ăn Chữa Lành',
                  subtitle: 'Phiên bản 1.0.0 (Build 100)',
                  onTap: () => _showAboutDialog(context),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 3. Logout Button (Red text / Destructive style)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const Key('profile_logout_button'),
                    onPressed: _isLoggingOut ? null : _confirmLogout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                          ),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thành tích của bạn'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 32,
              ),
              title: Text('Học viên tích cực'),
              subtitle: Text('Đã hoàn thành 5 bài học đầu tiên'),
            ),
            ListTile(
              leading: Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 32,
              ),
              title: Text('Chuỗi 7 ngày'),
              subtitle: Text('Học bài liên tục không gián đoạn'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trung tâm trợ giúp'),
        content: const Text(
          'Mọi thắc mắc về phương pháp nhịn ăn khoa học hoặc lỗi ứng dụng, vui lòng liên hệ hotline: 1900 6868 hoặc email support@nhinanchualanh.vn',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Về Nhìn Ăn Chữa Lành'),
        content: const Text(
          'Ứng dụng hướng dẫn nhịn ăn khoa học, cân bằng sức khỏe & phục hồi tự nhiên cho người Việt Nam.\n\nPhiên bản: 1.0.0 (Build 100)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
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

    if (confirmed == true) {
      _logout();
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

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
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
}
