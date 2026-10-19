import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/features/personalization/presentation/screens/personalization_screen.dart';
import 'package:e_learning_mobile/features/personalization/presentation/widgets/planner_daily_status_sheet.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp({
  required Widget child,
  WellnessDashboard? dashboard,
  ThemeData? theme,
  TextScaler? textScaler,
}) {
  return ProviderScope(
    overrides: [
      wellnessControllerProvider.overrideWith(
        (ref) => WellnessControllerMock(
          WellnessState(
            status: WellnessStatus.success,
            dashboard: dashboard ?? _mockDashboard(),
          ),
        ),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        textScaler: textScaler ?? TextScaler.noScaling,
      ),
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: child,
      ),
    ),
  );
}

WellnessDashboard _mockDashboard() {
  return WellnessDashboard(
    plan: WellnessPlan(
      id: 'plan-1',
      packageType: 'STANDARD',
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 27)),
      fastingHours: 16,
      eatingHours: 8,
      dailyFastStartMinuteOfDay: 1200,
      timezone: 'Asia/Ho_Chi_Minh',
      startWeightKg: 65.0,
      targetWeightKg: 60.0,
      status: 'ACTIVE',
      totalDays: 30,
      elapsedDays: 3,
      preparationDays: 3,
      fastingDays: 21,
      refeedDays: 6,
      createdAt: DateTime.now(),
    ),
    todayLog: WellnessDailyLog(
      logDate: DateTime.now(),
      waterMl: 750,
      workoutMinutes: 24,
      currentWeightKg: 64.2,
    ),
    fastingStatus: WellnessFastingStatus(
      state: 'FASTING',
      windowStartLocal: DateTime.now().subtract(const Duration(hours: 6)),
      windowEndLocal: DateTime.now().add(const Duration(hours: 10)),
      currentTimeLocal: DateTime.now(),
      progressPercent: 37.5,
      remainingMinutes: 574,
      label: 'GIAI ĐOẠN ĐỐT MỠ',
    ),
    todayResources: const WellnessResourceSet(
      workout: WellnessResourceItem(
        id: 'w-1',
        title: 'Shaped Lower Body Workout',
        resourceType: 'WORKOUT',
      ),
    ),
    todayInsight: WellnessInsight(
      insightDate: DateTime.now(),
      tip: 'Bổ sung nước ấm và một giấc ngủ ngắn giúp tái tạo năng lượng.',
    ),
  );
}

class WellnessControllerMock extends StateNotifier<WellnessState>
    implements WellnessController {
  WellnessControllerMock(super.state);

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> loadDashboard({bool isSilent = false}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> logWaterDelta(int deltaMl) async {}

  @override
  Future<void> logWorkout(int minutes, String type) async {}

  @override
  Future<void> logWeight(double weightKg) async {}

  @override
  Future<void> logMealTime([DateTime? time]) async {}

  @override
  Future<void> completeTask(String taskId) async {}

  @override
  Future<void> askMoodCoach(WellnessCoachMoodRequest request) async {}

  @override
  Future<void> generateMeal(WellnessCoachMealRequest request) async {}

  @override
  Future<void> savePlan(UpsertWellnessPlanRequest request) async {}

  @override
  Future<void> updateSchedule(UpdateWellnessScheduleRequest request) async {}

  @override
  Future<void> loadTimeline({int days = 30}) async {}
}

void main() {
  group('PersonalizationScreen Responsive & Device Adaptability', () {
    testWidgets('renders cleanly on Small Phone screen (320x568 - iPhone SE)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildTestApp(child: const PersonalizationScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kế hoạch'), findsOneWidget);
      expect(find.text('Cá nhân hóa Wellness'), findsOneWidget);
      expect(find.text('Trợ giúp'), findsOneWidget);
      expect(find.text('Bài tập'), findsOneWidget);
      expect(find.text('Nước'), findsWidgets);
    });

    testWidgets(
      'renders cleanly on Standard Phone screen (390x844 - iPhone 14/15/16)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildTestApp(child: const PersonalizationScreen()),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Lịch trình nhịn ăn của bạn'), findsOneWidget);
        expect(find.text('Shaped Lower Body Workout'), findsOneWidget);
        expect(find.text('BẮT ĐẦU BÀI TẬP'), findsOneWidget);
        expect(find.text('Bữa ăn đầu tiên'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly on Large Android Phone screen (412x915 - Pixel 8 Pro / Galaxy S24)',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildTestApp(child: const PersonalizationScreen()),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('GHI NƯỚC'), findsOneWidget);
        expect(find.text('Mẹo hàng ngày'), findsOneWidget);
        expect(find.text('Đốt mỡ'), findsOneWidget);
      },
    );

    testWidgets('renders cleanly on Tablet screen (768x1024 - iPad / Tablet)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildTestApp(child: const PersonalizationScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tiện ích Lối sống & Sức khỏe'), findsOneWidget);
      expect(find.text('Tiến trình 30 ngày'), findsOneWidget);
    });

    testWidgets('supports Large Text Accessibility Scale (1.4x scale factor)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildTestApp(
          child: const PersonalizationScreen(),
          textScaler: const TextScaler.linear(1.4),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kế hoạch'), findsOneWidget);
    });

    testWidgets('supports Dark Mode theme gracefully', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildTestApp(
          child: const PersonalizationScreen(),
          theme: AppTheme.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kế hoạch'), findsOneWidget);
    });

    testWidgets('opens Water Action Sheet when tapping GHI NƯỚC', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildTestApp(child: const PersonalizationScreen()),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('GHI NƯỚC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GHI NƯỚC'));
      await tester.pumpAndSettle();

      expect(find.text('Ghi nhận Lượng nước uống'), findsOneWidget);
      expect(find.text('Cốc nhỏ'), findsOneWidget);
      expect(find.text('Cốc chuẩn'), findsOneWidget);
      expect(find.text('Bình nước'), findsOneWidget);
    });

    testWidgets(
      'opens Daily Status Sheet with 9 BetterMe options when tapping TRẢ LỜI',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildTestApp(child: const PersonalizationScreen()),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('TRẢ LỜI'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('TRẢ LỜI'));
        await tester.pumpAndSettle();

        expect(find.byType(PlannerDailyStatusSheet), findsOneWidget);
        expect(find.text('Trạng thái hàng ngày'), findsOneWidget);
        expect(find.text('Tôi cảm thấy khát.'), findsOneWidget);
        expect(find.text('Tôi thấy đói.'), findsOneWidget);
        expect(find.text('Bụng tôi thấy khó chịu.'), findsOneWidget);
        expect(find.text('Tôi cảm thấy mệt mỏi.'), findsOneWidget);
        expect(
          find.text('Tôi cảm thấy có động lực để tập thể dục.'),
          findsOneWidget,
        );
        expect(find.text('Tôi đang thèm ăn kinh khủng.'), findsOneWidget);
        expect(find.text('Đóng'), findsOneWidget);
      },
    );

    testWidgets(
      'opens Workout Action Sheet without bottom overflow on compact height',
      (tester) async {
        // Test specifically on a compact height device where the 12px overflow previously occurred
        tester.view.physicalSize = const Size(375, 560);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildTestApp(child: const PersonalizationScreen()),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Bài tập'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bài tập'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Ghi nhận Hoạt động Thể chất'), findsOneWidget);
        expect(find.text('Đi bộ nhẹ nhàng'), findsOneWidget);
        expect(find.text('Yoga & Giãn cơ phục hồi'), findsOneWidget);
        expect(find.text('Shaped Lower Body Workout'), findsWidgets);
        expect(find.text('Chạy bộ / Vận động nhịp tim cao'), findsOneWidget);
      },
    );
  });
}
