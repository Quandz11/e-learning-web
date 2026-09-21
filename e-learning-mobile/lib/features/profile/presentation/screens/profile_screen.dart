import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_controller.dart';
import 'package:e_learning_mobile/features/notifications/data/notifications_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/features/progress/presentation/controllers/progress_controller.dart';
import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/theme/app_theme_extensions.dart';
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
      ref.read(progressControllerProvider.notifier).load();
      ref.read(learningControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final progressState = ref.watch(progressControllerProvider);
    final learningState = ref.watch(learningControllerProvider);

    final theme = Theme.of(context);
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    final streakDays = progressState.summary?.currentStreakDays ?? 7;
    final overallPercent = (progressState.summary?.overallProgressPercent ?? 60.0).toInt();
    final courseCount = learningState.enrollments.isNotEmpty ? learningState.enrollments.length : 3;
    final completedCount = progressState.summary?.completedLessonsCount ?? 5;
    final rawName = state.profile?.fullName;
    final fullName = (rawName != null && rawName.trim().isNotEmpty) ? rawName.trim() : 'Học viên';
    final rawEmail = state.profile?.email;
    final email = (rawEmail != null && rawEmail.trim().isNotEmpty) ? rawEmail.trim() : 'hocvien@nhinanchualanh.vn';

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: -0.3,
            color: context.textPrimary(),
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? colorScheme.surface : AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Làm mới hồ sơ',
            onPressed: () {
              controller.refresh();
              ref.read(progressControllerProvider.notifier).refresh();
              ref.read(learningControllerProvider.notifier).refresh();
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: context.textPrimary(),
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
                // 1. Profile Header Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.cardBg(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.cardBorder(),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: AppAvatar(
                          name: fullName,
                          imageUrl: state.profile?.avatarUrl,
                          size: 60,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.3,
                                color: context.textPrimary(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w300,
                                color: context.textSecondary(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.primaryContainer : AppColors.mint,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isDark ? colorScheme.outlineVariant : const Color(0xFFD3E6DC),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                streakDays >= 7 ? 'Thành viên Tích cực 🔥' : 'Học viên Thường xuyên 🌟',
                                style: TextStyle(
                                  color: isDark ? colorScheme.onPrimaryContainer : AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Three-slot Stats Strip (Bento Pods)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.cardBg(),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.cardBorder(),
                      width: 0.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(context, '$courseCount', 'Khóa học', Icons.menu_book_rounded, isDark ? colorScheme.primary : const Color(0xFF0F5B38), isDark ? colorScheme.surfaceContainerLow : const Color(0xFFF0F7F2)),
                      Container(height: 32, width: 0.8, color: context.cardBorder()),
                      _buildStatColumn(context, '$overallPercent%', 'Tiến độ', Icons.pie_chart_outline_rounded, const Color(0xFF2563EB), isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF)),
                      Container(height: 32, width: 0.8, color: context.cardBorder()),
                      _buildStatColumn(context, '$streakDays ngày', 'Streak', Icons.local_fire_department_rounded, const Color(0xFFD97706), isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section 1: Học tập & Thành tích
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
                  child: Text(
                    'HỌC TẬP & THÀNH TÍCH',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.textSecondary(),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: context.cardBg(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.cardBorder(),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildListTileItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: 'Hồ sơ của tôi',
                        subtitle: 'Cập nhật thông tin cá nhân & ảnh đại diện',
                        bgColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        onTap: () => context.push(AppRoutes.appProfileEdit),
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: context.cardBorder()),
                      _buildListTileItem(
                        context,
                        icon: Icons.emoji_events_outlined,
                        title: 'Thành tích & Huy hiệu',
                        subtitle: 'Đã hoàn thành $completedCount bài học & chuỗi $streakDays ngày',
                        bgColor: isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB),
                        iconColor: const Color(0xFFD97706),
                        badge: '$completedCount bài học',
                        onTap: () => _showAchievementsDialog(context),
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: context.cardBorder()),
                      _buildListTileItem(
                        context,
                        icon: Icons.history_edu_rounded,
                        title: 'Lịch sử học tập',
                        subtitle: 'Xem danh sách bài đã xem & tiến độ tích lũy',
                        bgColor: isDark ? colorScheme.surfaceContainerLow : const Color(0xFFF0F7F2),
                        iconColor: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                        onTap: () => context.push(AppRoutes.appProgress),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section 2: Hệ thống & Trợ giúp
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
                  child: Text(
                    'HỆ THỐNG & TRỢ GIÚP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.textSecondary(),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: context.cardBg(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.cardBorder(),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildListTileItem(
                        context,
                        icon: Icons.settings_outlined,
                        title: 'Cài đặt ứng dụng',
                        subtitle: 'Thông báo, bảo mật & bộ nhớ đệm',
                        bgColor: isDark ? const Color(0xFF4C1D95) : const Color(0xFFF5F3FF),
                        iconColor: const Color(0xFF7C3AED),
                        onTap: () => context.push(AppRoutes.appSettings),
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: context.cardBorder()),
                      _buildListTileItem(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: 'Trung tâm trợ giúp',
                        subtitle: 'Hỏi đáp bác sĩ & hỗ trợ kỹ thuật',
                        bgColor: isDark ? const Color(0xFF075985) : const Color(0xFFF0F9FF),
                        iconColor: const Color(0xFF0284C7),
                        onTap: () => _showSupportDialog(context),
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16, color: context.cardBorder()),
                      _buildListTileItem(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'Về ứng dụng Nhìn Ăn Chữa Lành',
                        subtitle: 'Phiên bản 1.0.0 (Build 100)',
                        bgColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF8FAFC),
                        iconColor: const Color(0xFF64748B),
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
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
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  Widget _buildStatColumn(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary(),
            fontWeight: FontWeight.w500,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textMuted(),
            fontWeight: FontWeight.w300,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildListTileItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    Color bgColor = const Color(0xFFF0F7F2),
    String? badge,
  }) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final effectiveBgColor = isDark ? iconColor.withValues(alpha: 0.18) : bgColor;
    final effectiveIconColor = isDark ? (iconColor == AppColors.primary ? const Color(0xFF4CAF50) : iconColor) : iconColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: effectiveBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                            color: context.textPrimary(),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? context.colorScheme.surfaceContainerHighest : const Color(0xFFF2F6F3),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? context.colorScheme.primary : const Color(0xFF0F5B38),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: context.textMuted(),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textMuted(),
              size: 20,
            ),
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
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
}
