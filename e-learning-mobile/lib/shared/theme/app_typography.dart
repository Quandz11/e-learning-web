import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static TextStyle _safeStyle(
    TextStyle? baseStyle, {
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    if (baseStyle == null) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme(TextTheme base) {
    return TextTheme(
      displayLarge: _safeStyle(
        base.displayLarge,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
      ),
      displayMedium: _safeStyle(
        base.displayMedium,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
      ),
      displaySmall: _safeStyle(
        base.displaySmall,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
      ),
      headlineLarge: _safeStyle(
        base.headlineLarge,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
      ),
      headlineMedium: _safeStyle(
        base.headlineMedium,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.25,
        letterSpacing: -0.5,
      ),
      headlineSmall: _safeStyle(
        base.headlineSmall,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      titleLarge: _safeStyle(
        base.titleLarge,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      titleMedium: _safeStyle(
        base.titleMedium,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      titleSmall: _safeStyle(
        base.titleSmall,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
      ),
      bodyLarge: _safeStyle(
        base.bodyLarge,
        fontSize: 15,
        fontWeight: FontWeight.w300,
        height: 1.5,
      ),
      bodyMedium: _safeStyle(
        base.bodyMedium,
        fontSize: 14,
        fontWeight: FontWeight.w300,
        height: 1.45,
      ),
      bodySmall: _safeStyle(
        base.bodySmall,
        fontSize: 12,
        fontWeight: FontWeight.w300,
        height: 1.4,
      ),
      labelLarge: _safeStyle(
        base.labelLarge,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      labelMedium: _safeStyle(
        base.labelMedium,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      labelSmall: _safeStyle(
        base.labelSmall,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }
}
