import 'package:e_learning_mobile/features/foundation/presentation/startup_failure_screen.dart';
import 'package:e_learning_mobile/shared/widgets/app_empty_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppLoadingView renders progress and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLoadingView(label: 'Please wait')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Please wait'), findsOneWidget);
  });

  testWidgets('AppErrorView renders message and retry button', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorView(
            message: 'Something failed',
            onRetry: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Something failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });

  testWidgets('AppEmptyView renders message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppEmptyView(message: 'Nothing here')),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('StartupFailureScreen shows user-safe message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StartupFailureScreen(
          message: 'The app configuration is invalid.',
        ),
      ),
    );

    expect(find.text('Startup failed'), findsOneWidget);
    expect(find.text('The app configuration is invalid.'), findsOneWidget);
  });
}
