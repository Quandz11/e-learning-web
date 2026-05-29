import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sign up',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referralController,
            decoration: const InputDecoration(
              labelText: 'Referral code (optional)',
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });

                    try {
                      await ref
                          .read(sessionControllerProvider.notifier)
                          .register(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                            fullName: _fullNameController.text.trim(),
                            phone: _phoneController.text.trim().isEmpty
                                ? null
                                : _phoneController.text.trim(),
                            referralCode:
                                _referralController.text.trim().isEmpty
                                ? null
                                : _referralController.text.trim(),
                          );

                      if (!context.mounted) return;
                      context.go(RoutePaths.login);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sign up successful. Please verify OTP.',
                          ),
                        ),
                      );
                    } catch (error) {
                      final mapped = ErrorMapper.map(error);
                      setState(() => _error = mapped.message);
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: Text(_loading ? 'Processing...' : 'Sign up'),
          ),
        ],
      ),
    );
  }
}
