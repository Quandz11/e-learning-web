import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/repositories/payment_repository.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(paymentRepositoryProvider);

    return AppScaffold(
      title: 'Orders',
      child: FutureBuilder(
        future: repository.getMyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load orders: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, index) {
              final order = orders[index];
              return ListTile(
                title: Text(
                  'Order #${order['payOSOrderCode'] ?? order['orderId']}',
                ),
                subtitle: Text(
                  'Status: ${order['status']} - Total: ${order['totalAmount']}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
