import 'package:flutter/material.dart';

class PublicPlaceholderScreen extends StatelessWidget {
  const PublicPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'The Phase 1 foundation is active. Authentication and features will be added next.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
