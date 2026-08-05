import 'package:flutter/material.dart';

class PaymentReturnPlaceholderScreen extends StatelessWidget {
  const PaymentReturnPlaceholderScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Return')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Payment return callback received.\n${uri.toString()}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
