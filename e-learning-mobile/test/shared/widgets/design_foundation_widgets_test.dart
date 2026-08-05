import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:e_learning_mobile/shared/widgets/app_avatar.dart';
import 'package:e_learning_mobile/shared/widgets/app_badge.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:e_learning_mobile/shared/widgets/app_card.dart';
import 'package:e_learning_mobile/shared/widgets/app_empty_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_error_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_loading_view.dart';
import 'package:e_learning_mobile/shared/widgets/app_page.dart';
import 'package:e_learning_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary button renders and invokes callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _wrap(AppButton(label: 'Continue', onPressed: () => tapped = true)),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('loading button disables repeated taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(
        AppButton(label: 'Continue', loading: true, onPressed: () => taps += 1),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(taps, 0);
  });

  testWidgets('disabled button does not invoke callback', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(AppButton(label: 'Continue', onPressed: null)),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(taps, 0);
  });

  testWidgets('text field displays label hint and error', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppTextField(
          labelText: 'Email',
          hintText: 'name@example.com',
          errorText: 'Invalid email.',
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('name@example.com'), findsOneWidget);
    expect(find.text('Invalid email.'), findsOneWidget);
  });

  testWidgets('text field preserves obscure text behavior', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppTextField(
          fieldKey: Key('password_field'),
          obscureText: true,
          labelText: 'Password',
        ),
      ),
    );

    final field = tester.widget<TextField>(
      find.byKey(const Key('password_field')),
    );
    expect(field.obscureText, isTrue);
  });

  testWidgets('card invokes tap callback when enabled', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _wrap(
        AppCard(onTap: () => tapped = true, child: const Text('Card content')),
      ),
    );

    await tester.tap(find.text('Card content'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('app page handles small viewport without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const AppPage(
          appBarTitle: 'Page',
          child: Column(
            children: [SizedBox(height: 600, child: Text('Scrollable body'))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('badge renders supported states', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Wrap(
          children: [
            AppBadge(label: 'Neutral'),
            AppBadge(label: 'Info', tone: AppBadgeTone.info),
            AppBadge(label: 'Success', tone: AppBadgeTone.success),
            AppBadge(label: 'Warning', tone: AppBadgeTone.warning),
            AppBadge(label: 'Error', tone: AppBadgeTone.error),
          ],
        ),
      ),
    );

    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
  });

  testWidgets('avatar renders initials and fallback safely', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            AppAvatar(name: 'Nguyễn Văn'),
            AppAvatar(),
          ],
        ),
      ),
    );

    expect(find.text('NV'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('loading error and empty render under light and dark themes', (
    tester,
  ) async {
    await tester.pumpWidget(
      Column(
        children: [
          Expanded(
            child: _wrap(
              const Column(
                children: [
                  AppLoadingView(),
                  AppErrorView(message: 'Problem'),
                  AppEmptyView(message: 'Nothing here'),
                ],
              ),
            ),
          ),
          Expanded(
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const Scaffold(
                body: Column(
                  children: [
                    AppLoadingView(),
                    AppErrorView(message: 'Problem'),
                    AppEmptyView(message: 'Nothing here'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    expect(find.text('Loading...'), findsNWidgets(2));
    expect(find.text('Problem'), findsNWidgets(2));
    expect(find.text('Nothing here'), findsNWidgets(2));
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}
