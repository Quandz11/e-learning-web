import 'package:flutter/material.dart';

class ProtectedPlaceholderScreen extends StatelessWidget {
  const ProtectedPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Area')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Authenticated foundation route placeholder.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
