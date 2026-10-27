import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:e_learning_mobile/features/running/presentation/screens/activity_detail_screen.dart';
import 'package:e_learning_mobile/features/running/presentation/screens/pre_run_screen.dart';
import 'package:e_learning_mobile/features/running/presentation/screens/rewards_inventory_screen.dart';
import 'package:e_learning_mobile/features/running/presentation/screens/run_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child, {double width = 320, double height = 640}) {
    return ProviderScope(
      overrides: [
        runningControllerProvider.overrideWith(
          (ref) => RunningController(),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: const TextScaler.linear(1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  testWidgets('ActivityDetailScreen renders smoothly without overflow on 320px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableWidget(const ActivityDetailScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Chạy bộ'), findsWidgets);
    expect(find.text('Phần thưởng'), findsOneWidget);
    expect(find.text('+ Mục tiêu'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PreRunScreen renders launchpad without overflow on 320px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableWidget(const PreRunScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chạy bộ'), findsWidgets);
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.text('Sẵn sàng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RewardsInventoryScreen renders badges without overflow on 320px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableWidget(const RewardsInventoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Kho phần thưởng'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RunResultScreen renders stats summary without overflow on 320px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sampleActivity = RunningActivity(
      id: 'act-sample',
      userId: 'u-1',
      distanceKm: 8.5,
      durationSeconds: 2712,
      paceFormatted: "5'19\"/km",
      caloriesBurned: 535,
      activityDate: DateTime.now(),
      title: 'Chạy bộ ngoài trời',
      trackingMode: 'GPS',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestableWidget(RunResultScreen(activity: sampleActivity)));
    await tester.pumpAndSettle();

    expect(find.text('Hoàn thành!'), findsOneWidget);
    expect(find.text('Xem phần thưởng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
