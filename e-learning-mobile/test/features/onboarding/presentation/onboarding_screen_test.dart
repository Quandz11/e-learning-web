import 'package:e_learning_mobile/app/bootstrap.dart';
import 'package:e_learning_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildOnboardingTestApp() {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const OnboardingScreen(),
      ),
    );
  }

  testWidgets('renders step 1 and navigates to step 2 on Tiếp tục', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildOnboardingTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Khám phá trang chủ'), findsOneWidget);
    expect(find.text('Tiếp tục →'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục →'));
    await tester.pumpAndSettle();

    expect(find.text('Tìm khóa học phù hợp'), findsOneWidget);
  });

  testWidgets('navigates through all 4 steps to final Bắt đầu sử dụng button', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildOnboardingTestApp());
    await tester.pumpAndSettle();

    // Step 1
    expect(find.text('Khám phá trang chủ'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục →'));
    await tester.pumpAndSettle();

    // Step 2
    expect(find.text('Tìm khóa học phù hợp'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục →'));
    await tester.pumpAndSettle();

    // Step 3
    expect(find.text('Tham gia cộng đồng'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục →'));
    await tester.pumpAndSettle();

    // Step 4
    expect(find.text('Quản lý tài khoản'), findsOneWidget);
    expect(find.text('Bắt đầu sử dụng →'), findsOneWidget);
  });

  testWidgets('tapping Bỏ qua marks onboarding done', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

    expect(container.read(hasSeenOnboardingProvider), isTrue);
  });
}
