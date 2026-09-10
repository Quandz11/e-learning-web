import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    super.key,
    this.buttonKey,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final Key? buttonKey;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final buttonIcon = icon;
    final buttonChild = loading
        ? const SizedBox(
            width: AppSizes.iconMd,
            height: AppSizes.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : buttonIcon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buttonIcon,
              const SizedBox(width: 8),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final disabled = loading || onPressed == null;
    final width = fullWidth ? double.infinity : null;
    final callback = disabled ? null : onPressed;

    return SizedBox(
      width: width,
      height: AppSizes.controlHeight,
      child: switch (variant) {
        AppButtonVariant.primary => FilledButton(
          key: buttonKey,
          onPressed: callback,
          child: buttonChild,
        ),
        AppButtonVariant.secondary => OutlinedButton(
          key: buttonKey,
          onPressed: callback,
          child: buttonChild,
        ),
        AppButtonVariant.text => TextButton(
          key: buttonKey,
          onPressed: callback,
          child: buttonChild,
        ),
        AppButtonVariant.destructive => FilledButton(
          key: buttonKey,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: callback,
          child: buttonChild,
        ),
      },
    );
  }
}
