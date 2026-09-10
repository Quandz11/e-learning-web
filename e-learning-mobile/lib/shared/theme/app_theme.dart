import 'package:e_learning_mobile/shared/theme/app_colors.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      surface: isLight ? AppColors.background : const Color(0xFF121B16),
      onSurface: isLight ? AppColors.textPrimary : const Color(0xFFE4EAE6),
      surfaceContainerLow: isLight
          ? AppColors.surface
          : const Color(0xFF1A2620),
      surfaceContainerLowest: isLight
          ? AppColors.surface
          : const Color(0xFF14201A),
      outline: isLight ? AppColors.sage : const Color(0xFF4A5C52),
      outlineVariant: isLight ? AppColors.border : const Color(0xFF2E3D35),
      error: AppColors.error,
    );
    final textTheme = AppTypography.textTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.25),
        selectionHandleColor: colorScheme.primary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.primary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppSizes.iconMd,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        hourMinuteColor: isLight ? const Color(0xFFF0F7F2) : const Color(0xFF1E2D24),
        hourMinuteTextColor: colorScheme.primary,
        dayPeriodColor: isLight ? const Color(0xFFF0F7F2) : const Color(0xFF1E2D24),
        dayPeriodTextColor: colorScheme.primary,
        dialHandColor: colorScheme.primary,
        dialBackgroundColor: isLight ? const Color(0xFFF0F7F2) : const Color(0xFF1E2D24),
        dialTextColor: colorScheme.onSurface,
        entryModeIconColor: colorScheme.primary,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isLight ? const Color(0xFFF0F7F2) : const Color(0xFF1E2D24),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
