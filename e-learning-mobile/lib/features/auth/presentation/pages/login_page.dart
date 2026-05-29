import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../controllers/auth_form_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _resolvePostLoginRoute(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from == null || from.isEmpty) {
      return RoutePaths.home;
    }

    try {
      final decoded = Uri.decodeComponent(from);
      if (decoded.startsWith('/') &&
          decoded != RoutePaths.login &&
          decoded != RoutePaths.register) {
        return decoded;
      }
    } catch (_) {}

    return RoutePaths.home;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(authFormControllerProvider);

    return AppScaffold(
      title: 'Sign in',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email or phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            if (formState.error != null)
              Text(formState.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: formState.loading
                  ? null
                  : () async {
                      final controller = ref.read(
                        authFormControllerProvider.notifier,
                      );
                      controller.setLoading(true);
                      try {
                        await ref
                            .read(sessionControllerProvider.notifier)
                            .login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            );
                        if (!context.mounted) return;
                        context.go(_resolvePostLoginRoute(context));
                      } catch (error) {
                        final apiError = ErrorMapper.map(error);
                        controller.setError(apiError.message);
                      }
                    },
              child: Text(formState.loading ? 'Signing in...' : 'Sign in'),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.register),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
