import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:flutter/material.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.isCircle = false,
  });

  final double? width;
  final double height;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          isCircle ? height / 2 : AppRadius.sm,
        ),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
