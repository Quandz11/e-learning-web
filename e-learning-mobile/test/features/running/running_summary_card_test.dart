import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/data/running_repository.dart';
import 'package:e_learning_mobile/features/running/presentation/widgets/running_summary_card.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRunningRepo implements RunningRepository {
  _FakeRunningRepo({required this.summary});

  final RunningSummary summary;

  @override
  Future<RunningSummary> getSummary() async => summary;

  @override
  Future<({List<RunningActivity> items, int totalCount})> getActivities({
    int page = 1,
    int pageSize = 20,
    int? month,
    int? year,
  }) async => (items: const <RunningActivity>[], totalCount: 0);

  @override
  Future<RunningActivity> createActivity(CreateRunningActivityDto dto) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteActivity(String id) async => true;
}

Widget _buildTestWidget({
  required RunningSummary summary,
  bool compact = false,
  double width = 360,
  double textScale = 1.0,
}) {
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
      runningRepositoryProvider.overrideWithValue(
        _FakeRunningRepo(summary: summary),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 700),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: RunningSummaryCard(compact: compact),
          ),
        ),
      ),
    ),
  );
}

void main() {
  const testSummary = RunningSummary(
    totalDistanceKm: 124.5,
    totalDurationSeconds: 45000,
    totalCalories: 8200,
    totalRunsCount: 18,
    weekDistanceKm: 8.5,
    monthDistanceKm: 32.0,
    longestRunKm: 10.5,
    currentStreakDays: 4,
  );

  testWidgets('renders compact RunningSummaryCard smoothly with zero overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestWidget(
        summary: testSummary,
        compact: true,
        width: 320,
        textScale: 1.4,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chạy bộ: 8.5/15 km'), findsOneWidget);
    expect(find.text('Chạy'), findsOneWidget);
    expect(find.byIcon(Icons.directions_run_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders full RunningSummaryCard with all details', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestWidget(
        summary: testSummary,
        compact: false,
        width: 360,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hoạt động Chạy bộ'), findsOneWidget);
    expect(find.textContaining('124.5 km'), findsOneWidget);
    expect(find.text('Mục tiêu tuần'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Chạy ngay (GPS)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles zero data safely without dividing by zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestWidget(
        summary: const RunningSummary(),
        compact: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chạy bộ: 0.0/15 km'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
