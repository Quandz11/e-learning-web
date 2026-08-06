import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/profile_api.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('profile screen shows summary and actions', (tester) async {
    await tester.pumpWidget(_pumpProfileScreen());
    await tester.pumpAndSettle();

    expect(
      find.text('Thông tin tài khoản và bảo mật của bạn.'),
      findsOneWidget,
    );
    expect(find.text('Người dùng học viên'), findsOneWidget);
    expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    expect(find.text('Bảo mật và 2FA'), findsOneWidget);
  });
}

Widget _pumpProfileScreen() {
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
      profileControllerProvider.overrideWith((ref) => _TestProfileController()),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
  );
}

class _TestProfileController extends ProfileController {
  _TestProfileController() : super(_NoopProfileRepository()) {
    state = ProfileState(
      status: ProfileStatus.success,
      profile: Profile(
        id: 'student-1',
        email: 'student@example.com',
        fullName: 'Người dùng học viên',
        phone: '0912345678',
        role: 'Student',
        status: 'Active',
        avatarUrl: null,
        isEmailVerified: true,
        isPhoneVerified: false,
        isTwoFactorEnabled: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
  }

  @override
  Future<void> load({bool refresh = false}) async {}
}

class _NoopProfileRepository extends ProfileRepository {
  _NoopProfileRepository() : super(api: _NoopProfileApi());
}

class _NoopProfileApi extends ProfileApi {
  _NoopProfileApi()
    : super(apiClient: ApiClient(Dio()), errorMapper: const DioErrorMapper());
}
