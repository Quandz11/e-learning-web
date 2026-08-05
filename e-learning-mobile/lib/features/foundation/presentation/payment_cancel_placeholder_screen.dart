import 'package:flutter/material.dart';

class PaymentCancelPlaceholderScreen extends StatelessWidget {
  const PaymentCancelPlaceholderScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Cancelled')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Payment cancel callback received.\n${uri.toString()}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
