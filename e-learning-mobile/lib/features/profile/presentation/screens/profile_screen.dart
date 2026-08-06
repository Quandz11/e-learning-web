import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_avatar.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
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

    return AppPage(
      includeScaffold: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Cá nhân',
            subtitle: 'Thông tin tài khoản và bảo mật của bạn.',
            trailing: IconButton(
              tooltip: 'Làm mới hồ sơ',
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.isLoading) ...[
            const AppLoadingView(label: 'Đang tải hồ sơ...'),
          ] else if (state.status == ProfileStatus.failure &&
              state.profile == null) ...[
            AppErrorView(
              message: state.message ?? 'Không thể tải hồ sơ.',
              onRetry: controller.load,
            ),
          ] else if (state.profile != null) ...[
            _ProfileSummaryCard(
              fullName: state.profile!.fullName,
              email: state.profile!.email,
              phone: state.profile!.phone,
              role: state.profile!.role,
              status: state.profile!.status,
              avatarUrl: state.profile!.avatarUrl,
              isEmailVerified: state.profile!.isEmailVerified,
              isPhoneVerified: state.profile!.isPhoneVerified,
              isTwoFactorEnabled: state.profile!.isTwoFactorEnabled,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileActionCard(
              title: 'Chỉnh sửa hồ sơ',
              icon: Icons.edit_outlined,
              onTap: () => context.push(AppRoutes.appProfileEdit),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileActionCard(
              title: 'Đổi mật khẩu',
              icon: Icons.lock_outline,
              onTap: () => context.push(AppRoutes.appProfileChangePassword),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileActionCard(
              title: 'Bảo mật và 2FA',
              icon: Icons.verified_user_outlined,
              subtitle: state.profile!.isTwoFactorEnabled
                  ? 'Xác thực hai lớp đang bật'
                  : 'Xác thực hai lớp đang tắt',
              onTap: () => context.push(AppRoutes.appProfileSecurity),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: const Key('profile_logout_button'),
              label: 'Đăng xuất',
              variant: AppButtonVariant.destructive,
              onPressed: _logout,
              loading: _isLoggingOut,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

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

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.avatarUrl,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isTwoFactorEnabled,
  });

  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? avatarUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isTwoFactorEnabled;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: fullName, imageUrl: avatarUrl, size: 72),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(email),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileRow(label: 'Số điện thoại', value: phone ?? 'Chưa cập nhật'),
          _ProfileRow(label: 'Vai trò', value: role),
          _ProfileRow(label: 'Trạng thái', value: status),
          _ProfileRow(
            label: 'Email',
            value: isEmailVerified ? 'Đã xác minh' : 'Chưa xác minh',
          ),
          _ProfileRow(
            label: 'Điện thoại',
            value: isPhoneVerified ? 'Đã xác minh' : 'Chưa xác minh',
          ),
          _ProfileRow(
            label: 'Xác thực hai lớp',
            value: isTwoFactorEnabled ? 'Đang bật' : 'Đang tắt',
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
