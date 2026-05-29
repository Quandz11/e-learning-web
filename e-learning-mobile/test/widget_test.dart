import 'package:e_learning_mobile/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoadingView renders progress indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
