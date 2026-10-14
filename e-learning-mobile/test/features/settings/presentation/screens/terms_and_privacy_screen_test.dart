import 'package:e_learning_mobile/features/settings/presentation/screens/terms_and_privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TermsAndPrivacyScreen renders terms tab by default', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TermsAndPrivacyScreen()));

    expect(find.text('Pháp lý & Quyền riêng tư'), findsOneWidget);
    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(find.text('Tuyên bố miễn trừ trách nhiệm y tế'), findsOneWidget);
  });

  testWidgets(
    'TermsAndPrivacyScreen renders privacy tab when initialIndex is 1',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TermsAndPrivacyScreen(initialIndex: 1)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cam kết bảo vệ dữ liệu sức khỏe'), findsOneWidget);
      expect(find.text('1. Dữ liệu chúng tôi thu thập'), findsOneWidget);
    },
  );
}
