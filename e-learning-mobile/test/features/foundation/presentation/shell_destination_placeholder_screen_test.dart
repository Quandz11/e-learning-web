import 'package:e_learning_mobile/features/foundation/presentation/shell_destination_placeholder_screen.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home placeholder renders title and shared primitives', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const HomePlaceholderScreen()));

    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(AppPage), findsOneWidget);
    expect(find.byType(AppSectionHeader), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('learning placeholder renders title', (tester) async {
    await tester.pumpWidget(_wrap(const LearningPlaceholderScreen()));

    expect(find.text('Learning'), findsOneWidget);
  });

  testWidgets('community placeholder renders title', (tester) async {
    await tester.pumpWidget(_wrap(const CommunityPlaceholderScreen()));

    expect(find.text('Community'), findsOneWidget);
  });

  testWidgets('profile placeholder renders title', (tester) async {
    await tester.pumpWidget(_wrap(const ProfilePlaceholderScreen()));

    expect(find.text('Profile'), findsOneWidget);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}
