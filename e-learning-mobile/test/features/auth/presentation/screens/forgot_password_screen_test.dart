import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('forgot-password screen renders email field by default and validates', (
    tester,
  ) async {
    await tester.pumpWidget(_pumpForgotPasswordScreen());

    expect(find.text('Khôi phục mật khẩu'), findsOneWidget);
    expect(
      find.byKey(const Key('forgot_password_email_field')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('forgot_password_submit_button')));
    await tester.pump();

    expect(find.text('Vui lòng nhập địa chỉ email.'), findsOneWidget);
  });

  testWidgets('forgot-password screen switches to phone tab and validates phone input', (
    tester,
  ) async {
    await tester.pumpWidget(_pumpForgotPasswordScreen());

    // Switch to Phone tab
    await tester.tap(find.text('Số điện thoại'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('forgot_password_phone_field')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('forgot_password_submit_button')));
    await tester.pump();

    expect(find.text('Vui lòng nhập số điện thoại.'), findsOneWidget);
  });
}

Widget _pumpForgotPasswordScreen() {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig(
          apiBaseUrl: Uri.parse('https://api.example.com/api'),
          flavor: AppFlavor.dev,
          paymentReturnUrl: Uri.parse('skvi://payment/result'),
          paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
        ),
      ),
      sessionStorageProvider.overrideWithValue(InMemorySessionStorage()),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          onRequestForgotPasswordOtp: (_) async => 'OTP đã được gửi.',
        ),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: ForgotPasswordScreen()),
  );
}
