import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppBadgeTone { neutral, info, success, warning, error }

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForTone(tone);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.foreground),
        ),
      ),
    );
  }

  _BadgeColors _colorsForTone(AppBadgeTone tone) {
    return switch (tone) {
      AppBadgeTone.neutral => const _BadgeColors(
        background: Color(0xFFE8EDF2),
        foreground: AppColors.neutral,
      ),
      AppBadgeTone.info => const _BadgeColors(
        background: Color(0xFFE8EEFF),
        foreground: AppColors.info,
      ),
      AppBadgeTone.success => const _BadgeColors(
        background: Color(0xFFE6F4EA),
        foreground: AppColors.success,
      ),
      AppBadgeTone.warning => const _BadgeColors(
        background: Color(0xFFFFF3D6),
        foreground: AppColors.warning,
      ),
      AppBadgeTone.error => const _BadgeColors(
        background: Color(0xFFFDE7E9),
        foreground: AppColors.danger,
      ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
