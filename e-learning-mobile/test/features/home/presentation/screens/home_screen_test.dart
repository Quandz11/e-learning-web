import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';
import 'package:e_learning_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:e_learning_mobile/features/learning/data/learning_repository.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/profile_api.dart';
import 'package:e_learning_mobile/features/profile/data/profile_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_state.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:e_learning_mobile/shared/widgets/app_avatar.dart';
import 'package:e_learning_mobile/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_home_repository.dart';
import '../../../../helpers/fake_learning_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('shows loading state before content resolves', (tester) async {
    final completer = Completer<HomeLoadResult>();
    final harness = _buildHarness(
      repository: FakeHomeRepository(onLoad: () => completer.future),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pump();

    expect(find.text('Khóa học nổi bật'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('shows personalized greeting and quick actions', (tester) async {
    final harness = _buildHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Chào buổi sáng'), findsOneWidget);
    expect(find.text('Tiếp tục học'), findsWidgets);
    expect(find.text('Khóa học'), findsWidgets);
    expect(find.text('Cộng đồng'), findsWidgets);
    expect(find.text('Kiến thức'), findsWidgets);
    expect(find.text('Tư vấn'), findsWidgets);
    expect(find.text('Tiến độ'), findsWidgets);
  });

  testWidgets('falls back to generic greeting when profile is unavailable', (
    tester,
  ) async {
    final harness = _buildHarness(profileState: const ProfileState());
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Chào buổi sáng'), findsOneWidget);
    expect(find.text('Học viên'), findsWidgets);
  });

  testWidgets('shows continue learning and navigates to learning', (
    tester,
  ) async {
    final harness = _buildHarness();
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Tiếp tục học'), findsWidgets);
    final continueButton = find.widgetWithText(AppButton, 'Tiếp tục học').first;
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Khóa học của tôi'), findsOneWidget);
  });

  testWidgets('omits continue learning when there are no enrollments', (
    tester,
  ) async {
    final harness = _buildHarness(
      repository: FakeHomeRepository(
        result: HomeLoadResult(
          featuredCourses: fakeHomeLoadResult().featuredCourses,
          continueLearning: null,
          categories: fakeHomeLoadResult().categories,
          articles: fakeHomeLoadResult().articles,
          testimonials: fakeHomeLoadResult().testimonials,
        ),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppButton, 'Tiếp tục học'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('formats course prices and shows thumbnail fallback', (
    tester,
  ) async {
    final harness = _buildHarness(
      repository: FakeHomeRepository(
        result: fakeHomeLoadResult(
          featuredCourses: [
            HomeCourse(
              id: 'course-1',
              title: 'Khóa học chuyên sâu',
              price: 1200000,
              isFree: false,
              isPublished: true,
              createdAt: DateTime.utc(2026, 1, 1),
              instructorName: 'Giảng viên A',
              thumbnailUrl: null,
            ),
          ],
        ),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('1.200.000 ₫'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
  });

  testWidgets('article failure does not hide featured courses', (tester) async {
    final harness = _buildHarness(
      repository: FakeHomeRepository(
        result: HomeLoadResult(
          featuredCourses: fakeHomeLoadResult().featuredCourses,
          continueLearning: fakeHomeLoadResult().continueLearning,
          categories: fakeHomeLoadResult().categories,
          articles: const [],
          testimonials: fakeHomeLoadResult().testimonials,
          articleIssue: const HomeSectionIssue(
            failure: AppFailure(
              type: AppFailureType.server,
              message: 'Server error',
            ),
          ),
        ),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Khóa học nổi bật'), findsOneWidget);
    expect(
      find.text('Máy chủ đang bận. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
  });

  testWidgets('primary failure renders retry state', (tester) async {
    final harness = _buildHarness(
      repository: FakeHomeRepository(
        error: const AppFailure(
          type: AppFailureType.server,
          message: 'Server error',
        ),
      ),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(
      find.text('Máy chủ đang bận. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'xem tat ca navigates to learning and avatar navigates to profile',
    (tester) async {
      final harness = _buildHarness();
      addTearDown(harness.container.dispose);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      final viewAllButton = find.widgetWithText(TextButton, 'Xem tất cả').first;
      await tester.ensureVisible(viewAllButton);
      await tester.pumpAndSettle();
      await tester.tap(viewAllButton);
      await tester.pumpAndSettle();
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        AppRoutes.appLearning,
      );

      harness.router.go(AppRoutes.appHome);
      await tester.pumpAndSettle();
      final avatarTapTarget = find.ancestor(
        of: find.byType(AppAvatar).first,
        matching: find.byType(InkWell),
      );
      await tester.tap(avatarTapTarget.first);
      await tester.pumpAndSettle();
      expect(find.text('Hồ sơ của tôi'), findsOneWidget);
    },
  );

  testWidgets('narrow layout and large text stay stable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = _buildHarness(
      mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
    );
    addTearDown(harness.container.dispose);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

_HomeHarness _buildHarness({
  FakeHomeRepository? repository,
  ProfileState? profileState,
  MediaQueryData? mediaQuery,
}) {
  final appConfig = AppConfig(
    apiBaseUrl: Uri.parse('https://api.example.com/api'),
    flavor: AppFlavor.dev,
    paymentReturnUrl: Uri.parse('skvi://payment/result'),
    paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
  );

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(appConfig),
      sessionStorageProvider.overrideWithValue(InMemorySessionStorage()),
      sessionControllerProvider.overrideWith(
        (ref) => _TestSessionController(
          SessionState.authenticated(
            AppSession(
              accessToken: 'access',
              refreshToken: 'refresh',
              expiresAt: DateTime.utc(2027, 1, 1),
            ),
          ),
        ),
      ),
      homeRepositoryProvider.overrideWithValue(
        repository ?? FakeHomeRepository(),
      ),
      learningRepositoryProvider.overrideWithValue(FakeLearningRepository()),
      profileControllerProvider.overrideWith(
        (ref) => _TestProfileController(
          profileState ??
              ProfileState(
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
                  isPhoneVerified: true,
                  isTwoFactorEnabled: false,
                  createdAt: DateTime.utc(2026, 1, 1),
                  updatedAt: DateTime.utc(2026, 1, 2),
                ),
              ),
        ),
      ),
      homeClockProvider.overrideWithValue(() => DateTime(2026, 8, 6, 8)),
    ],
  );

  final router = container.read(appRouterProvider);
  final app = UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: mediaQuery ?? const MediaQueryData(),
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
      ),
    ),
  );

  return _HomeHarness(container: container, router: router, app: app);
}

class _HomeHarness {
  const _HomeHarness({
    required this.container,
    required this.router,
    required this.app,
  });

  final ProviderContainer container;
  final GoRouter router;
  final Widget app;
}

class _TestSessionController extends SessionController {
  _TestSessionController(SessionState initialState)
    : super(
        SessionRepository(
          storage: InMemorySessionStorage(),
          config: AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
        ),
      ) {
    state = initialState;
  }
}

class _TestProfileController extends ProfileController {
  _TestProfileController(ProfileState initialState)
    : super(_NoopProfileRepository()) {
    state = initialState;
  }

  @override
  Future<void> load({bool refresh = false}) async {}

  @override
  Future<void> refresh() async {}
}

class _NoopProfileRepository extends ProfileRepository {
  _NoopProfileRepository() : super(api: _NoopProfileApi());
}

class _NoopProfileApi extends ProfileApi {
  _NoopProfileApi()
    : super(apiClient: ApiClient(Dio()), errorMapper: const DioErrorMapper());
}
