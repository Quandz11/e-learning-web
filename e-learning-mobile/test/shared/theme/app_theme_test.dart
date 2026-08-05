import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme is created', () {
    final theme = AppTheme.light();

    expect(theme.brightness, Brightness.light);
    expect(theme.useMaterial3, isTrue);
  });

  test('dark theme is created', () {
    final theme = AppTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.useMaterial3, isTrue);
  });

  test('required color roles exist', () {
    final scheme = AppTheme.light().colorScheme;

    expect(scheme.primary, isNot(Colors.transparent));
    expect(scheme.surface, isNot(Colors.transparent));
    expect(scheme.error, isNot(Colors.transparent));
    expect(scheme.outlineVariant, isNot(Colors.transparent));
  });

  test('text styles required by shared components exist', () {
    final textTheme = AppTheme.light().textTheme;

    expect(textTheme.headlineSmall, isNotNull);
    expect(textTheme.titleLarge, isNotNull);
    expect(textTheme.titleMedium, isNotNull);
    expect(textTheme.bodyMedium, isNotNull);
    expect(textTheme.bodySmall, isNotNull);
    expect(textTheme.labelLarge, isNotNull);
    expect(textTheme.labelMedium, isNotNull);
  });

  test('button and input themes have accessible control sizes', () {
    final theme = AppTheme.light();
    final filledStyle = theme.filledButtonTheme.style;
    final outlinedStyle = theme.outlinedButtonTheme.style;

    expect(
      filledStyle?.minimumSize?.resolve(<WidgetState>{})?.height,
      greaterThanOrEqualTo(48),
    );
    expect(
      outlinedStyle?.minimumSize?.resolve(<WidgetState>{})?.height,
      greaterThanOrEqualTo(48),
    );
    expect(theme.inputDecorationTheme.contentPadding, isNotNull);
  });
}
