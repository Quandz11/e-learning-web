import 'package:flutter/material.dart';

extension ThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;

  Color cardBg([Color? lightColor]) {
    if (isDark) {
      return colorScheme.surfaceContainerLow;
    }
    return lightColor ?? colorScheme.surface;
  }

  Color chipBg(bool isSelected, [Color? lightSelected, Color? lightUnselected]) {
    if (isSelected) {
      return colorScheme.primary;
    }
    if (isDark) {
      return colorScheme.surfaceContainerHighest;
    }
    return lightUnselected ?? const Color(0xFFF4F6F5);
  }

  Color chipText(bool isSelected, [Color? lightSelected, Color? lightUnselected]) {
    if (isSelected) {
      return Colors.white;
    }
    if (isDark) {
      return colorScheme.onSurface;
    }
    return lightUnselected ?? const Color(0xFF334036);
  }

  Color cardBorder([Color? lightColor]) {
    if (isDark) {
      return colorScheme.outlineVariant;
    }
    return lightColor ?? const Color(0xFFE2EBE5);
  }

  Color textPrimary([Color? lightColor]) {
    if (isDark) {
      return colorScheme.onSurface;
    }
    return lightColor ?? const Color(0xFF16251E);
  }

  Color textSecondary([Color? lightColor]) {
    if (isDark) {
      return colorScheme.onSurfaceVariant;
    }
    return lightColor ?? const Color(0xFF55645B);
  }

  Color textMuted([Color? lightColor]) {
    if (isDark) {
      return colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    }
    return lightColor ?? const Color(0xFF8E9E94);
  }
}
