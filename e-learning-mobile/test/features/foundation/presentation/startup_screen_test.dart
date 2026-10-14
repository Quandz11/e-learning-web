import 'package:e_learning_mobile/features/foundation/presentation/startup_screen.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup screen renders app name and progress indicator', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const StartupScreen()));

    expect(find.text(StartupScreen.appName), findsOneWidget);
    expect(find.text(StartupScreen.message), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('startup screen exposes accessible semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_buildApp(const StartupScreen()));
      final semanticsTree = tester
          .getSemantics(find.byType(StartupScreen))
          .toStringDeep();

      expect(
        semanticsTree,
        contains('Đang khởi động ${StartupScreen.appName}'),
      );
      expect(semanticsTree, contains('Đang tải dữ liệu khởi động'));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('startup screen renders in light theme', (tester) async {
    await tester.pumpWidget(
      _buildApp(const StartupScreen(), themeMode: ThemeMode.light),
    );

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup screen renders in dark theme', (tester) async {
    await tester.pumpWidget(
      _buildApp(const StartupScreen(), themeMode: ThemeMode.dark),
    );

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup screen does not overflow on small viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildApp(const StartupScreen()));

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup screen does not overflow with large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: const StartupScreen(),
        ),
      ),
    );

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildApp(Widget child, {ThemeMode themeMode = ThemeMode.system}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    home: child,
  );
}
