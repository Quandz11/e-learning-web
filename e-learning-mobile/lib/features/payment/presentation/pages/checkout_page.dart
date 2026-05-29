import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env_loader.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/models/payment_models.dart';
import '../../data/repositories/payment_repository.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _courseIdController = TextEditingController();
  final _referralController = TextEditingController();
  final _wellnessController = TextEditingController();
  String? _message;
  String? _latestOrderId;
  int? _latestOrderCode;
  bool _loading = false;

  String _buildPaymentResultLocation(String orderId, int? orderCode) {
    return Uri(
      path: RoutePaths.paymentResult,
      queryParameters: {
        'orderId': orderId,
        if (orderCode != null) 'orderCode': orderCode.toString(),
      },
    ).toString();
  }

  @override
  void dispose() {
    _courseIdController.dispose();
    _referralController.dispose();
    _wellnessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final env = ref.watch(appEnvProvider);

    return AppScaffold(
      title: 'Checkout',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter course IDs or a wellness package code to create checkout order.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _courseIdController,
            decoration: const InputDecoration(
              labelText: 'Course ID (comma separated)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wellnessController,
            decoration: const InputDecoration(
              labelText: 'Wellness package code',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referralController,
            decoration: const InputDecoration(labelText: 'Referral code'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final router = GoRouter.of(context);
                    final repository = ref.read(paymentRepositoryProvider);
                    setState(() {
                      _loading = true;
                      _message = null;
                    });

                    try {
                      final courseIds = _courseIdController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final result = await repository.createCheckout(
                        CheckoutRequestModel(
                          courseIds: courseIds,
                          wellnessPackageCode:
                              _wellnessController.text.trim().isEmpty
                              ? null
                              : _wellnessController.text.trim(),
                          referralCode: _referralController.text.trim().isEmpty
                              ? null
                              : _referralController.text.trim(),
                          returnUrl: env.paymentReturnUrl.isEmpty
                              ? null
                              : env.paymentReturnUrl,
                          cancelUrl: env.paymentCancelUrl.isEmpty
                              ? null
                              : env.paymentCancelUrl,
                        ),
                      );

                      setState(() {
                        _message =
                            'Order: ${result.orderId} | Status: ${result.status}';
                        _latestOrderId = result.orderId;
                        _latestOrderCode = result.payOSOrderCode;
                      });

                      if (!result.requiresPayment) {
                        if (!mounted) {
                          return;
                        }

                        router.push(
                          _buildPaymentResultLocation(
                            result.orderId,
                            result.payOSOrderCode,
                          ),
                        );
                        return;
                      }

                      final checkoutUrl = result.checkoutUrl;
                      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
                        await launchUrl(
                          Uri.parse(checkoutUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (error) {
                      setState(() => _message = 'Checkout failed: $error');
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: Text(_loading ? 'Creating order...' : 'Create checkout'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
            if (_latestOrderId != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    _buildPaymentResultLocation(
                      _latestOrderId!,
                      _latestOrderCode,
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Check payment result'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
