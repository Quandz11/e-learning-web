import 'package:flutter/material.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}
