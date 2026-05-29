import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  const PaymentResultPage({super.key, this.orderId, this.orderCode});

  final String? orderId;
  final int? orderCode;

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage> {
  Map<String, dynamic>? _orderStatus;
  String? _error;
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderStatus(refresh: true, showBlockingLoader: true);
    });
  }

  bool get _hasOrderId => (widget.orderId ?? '').trim().isNotEmpty;
  bool get _hasOrderCode => (widget.orderCode ?? 0) > 0;

  String get _resolvedStatus {
    final raw = _orderStatus?['status']?.toString() ?? 'PENDING';
    return raw.toUpperCase();
  }

  Color _toneColor(BuildContext context) {
    switch (_resolvedStatus) {
      case 'PAID':
        return Colors.green;
      case 'FAILED':
      case 'CANCELLED':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _toneIcon() {
    switch (_resolvedStatus) {
      case 'PAID':
        return Icons.check_circle;
      case 'FAILED':
      case 'CANCELLED':
        return Icons.error;
      default:
        return Icons.hourglass_top;
    }
  }

  String _formatAmount(dynamic amount) {
    final value = amount is num
        ? amount.toDouble()
        : double.tryParse(amount?.toString() ?? '') ?? 0;
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDateTime(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      return '-';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal());
  }

  List<Map<String, dynamic>> _readItems() {
    final raw = _orderStatus?['items'];
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> _loadOrderStatus({
    required bool refresh,
    required bool showBlockingLoader,
  }) async {
    if (!_hasOrderId && !_hasOrderCode) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _checking = false;
        _orderStatus = null;
        _error =
            'Missing order reference. Please open this screen from checkout.';
      });
      return;
    }

    setState(() {
      if (showBlockingLoader) {
        _loading = true;
      } else {
        _checking = true;
      }
      _error = null;
    });

    try {
      final repository = ref.read(paymentRepositoryProvider);
      final result = _hasOrderCode
          ? await repository.getOrderStatusByCode(
              widget.orderCode!,
              refresh: refresh,
            )
          : await repository.getOrderStatus(
              widget.orderId!.trim(),
              refresh: refresh,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _orderStatus = result;
        _loading = false;
        _checking = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _checking = false;
        _error = 'Failed to load order status: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _readItems();
    final toneColor = _toneColor(context);

    return AppScaffold(
      title: 'Payment result',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null && _orderStatus == null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _checking
                        ? null
                        : () => _loadOrderStatus(
                            refresh: true,
                            showBlockingLoader: false,
                          ),
                    icon: const Icon(Icons.refresh),
                    label: Text(_checking ? 'Checking...' : 'Retry'),
                  ),
                ] else if (_orderStatus != null) ...[
                  Card(
                    child: ListTile(
                      leading: Icon(_toneIcon(), color: toneColor),
                      title: Text(
                        _resolvedStatus,
                        style: TextStyle(
                          color: toneColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _resolvedStatus == 'PAID'
                            ? 'Payment completed successfully.'
                            : _resolvedStatus == 'FAILED' ||
                                  _resolvedStatus == 'CANCELLED'
                            ? 'Payment did not complete. Please retry checkout if needed.'
                            : 'Payment is pending. Please check again after transfer.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Order ID',
                            value: _orderStatus?['orderId']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Order code',
                            value:
                                _orderStatus?['payOSOrderCode']?.toString() ??
                                '-',
                          ),
                          _InfoRow(
                            label: 'Status',
                            value: _orderStatus?['status']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Last payment status',
                            value:
                                _orderStatus?['lastPaymentStatus']
                                    ?.toString() ??
                                '-',
                          ),
                          _InfoRow(
                            label: 'Total amount',
                            value: _formatAmount(_orderStatus?['totalAmount']),
                          ),
                          _InfoRow(
                            label: 'Paid at',
                            value: _formatDateTime(_orderStatus?['paidAt']),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            const Text('No items')
                          else
                            ...items.map((item) {
                              final isFree = item['isFree'] == true;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title']?.toString() ?? '-',
                                      ),
                                    ),
                                    Text(
                                      isFree
                                          ? 'Free'
                                          : _formatAmount(item['price']),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _checking
                        ? null
                        : () => _loadOrderStatus(
                            refresh: true,
                            showBlockingLoader: false,
                          ),
                    icon: const Icon(Icons.sync),
                    label: Text(_checking ? 'Checking...' : 'Refresh status'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RoutePaths.orders),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Order history'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RoutePaths.myCourses),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('My courses'),
                  ),
                ],
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
