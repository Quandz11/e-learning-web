import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/logout_request.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShellDestinationPlaceholderScreen(
      title: 'Home',
      description: 'Home content will be implemented in a later phase.',
    );
  }
}

class LearningPlaceholderScreen extends StatelessWidget {
  const LearningPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShellDestinationPlaceholderScreen(
      title: 'Learning',
      description: 'Learning content will be implemented in a later phase.',
    );
  }
}

class CommunityPlaceholderScreen extends StatelessWidget {
  const CommunityPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShellDestinationPlaceholderScreen(
      title: 'Community',
      description: 'Community content will be implemented in a later phase.',
    );
  }
}

class ProfilePlaceholderScreen extends ConsumerStatefulWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  ConsumerState<ProfilePlaceholderScreen> createState() =>
      _ProfilePlaceholderScreenState();
}

class _ProfilePlaceholderScreenState
    extends ConsumerState<ProfilePlaceholderScreen> {
  bool _isLoggingOut = false;

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

  @override
  Widget build(BuildContext context) {
    return _ShellDestinationPlaceholderScreen(
      title: 'Profile',
      description: 'Profile content will be implemented in a later phase.',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            buttonKey: const Key('profile_logout_button'),
            label: 'Log out',
            onPressed: _logout,
            loading: _isLoggingOut,
          ),
        ],
      ),
    );
  }
}

class _ShellDestinationPlaceholderScreen extends StatelessWidget {
  const _ShellDestinationPlaceholderScreen({
    required this.title,
    required this.description,
    this.footer,
  });

  final String title;
  final String description;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      includeScaffold: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(title: title, subtitle: description),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
