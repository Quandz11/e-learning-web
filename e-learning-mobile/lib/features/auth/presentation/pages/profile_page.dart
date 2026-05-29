import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/auth/session_state.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);

    return AppScaffold(
      title: 'Account',
      child: state.maybeWhen(
        authenticated: (session) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Full name'),
              subtitle: Text(session.user.fullName),
            ),
            ListTile(
              title: const Text('Email'),
              subtitle: Text(session.user.email),
            ),
            ListTile(
              title: const Text('Role'),
              subtitle: Text(session.user.role),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(sessionControllerProvider.notifier).logout();
                if (!context.mounted) return;
                context.go(RoutePaths.login);
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        orElse: () => const Center(child: Text('You are not signed in.')),
      ),
    );
  }
}
