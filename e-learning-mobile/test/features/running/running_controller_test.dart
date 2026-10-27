import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/data/running_repository.dart';
import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRunningRepository implements RunningRepository {
  RunningSummary summary = const RunningSummary(
    totalDistanceKm: 25.0,
    totalDurationSeconds: 9000,
    totalCalories: 1600,
    totalRunsCount: 5,
    weekDistanceKm: 10.0,
    monthDistanceKm: 25.0,
    longestRunKm: 8.0,
    currentStreakDays: 3,
  );

  final List<RunningActivity> activities = [];

  @override
  Future<RunningSummary> getSummary() async => summary;

  @override
  Future<({List<RunningActivity> items, int totalCount})> getActivities({
    int page = 1,
    int pageSize = 20,
    int? month,
    int? year,
  }) async {
    return (items: List<RunningActivity>.from(activities), totalCount: activities.length);
  }

  @override
  Future<RunningActivity> createActivity(CreateRunningActivityDto dto) async {
    final activity = RunningActivity(
      id: 'act-${activities.length + 1}',
      userId: 'test-user',
      distanceKm: dto.distanceKm,
      durationSeconds: dto.durationSeconds,
      paceFormatted: "6'00\"/km",
      caloriesBurned: (dto.distanceKm * 65 * 1.036).round(),
      activityDate: dto.activityDate ?? DateTime.now(),
      title: dto.title ?? 'Chạy bộ',
      notes: dto.notes,
      trackingMode: dto.trackingMode,
      createdAt: DateTime.now(),
    );
    activities.insert(0, activity);
    summary = RunningSummary(
      totalDistanceKm: summary.totalDistanceKm + dto.distanceKm,
      weekDistanceKm: summary.weekDistanceKm + dto.distanceKm,
      totalRunsCount: summary.totalRunsCount + 1,
    );
    return activity;
  }

  @override
  Future<bool> deleteActivity(String id) async {
    final before = activities.length;
    activities.removeWhere((a) => a.id == id);
    return activities.length < before;
  }
}

void main() {
  late FakeRunningRepository fakeRepository;
  late RunningController controller;

  setUp(() {
    fakeRepository = FakeRunningRepository();
    controller = RunningController(fakeRepository);
  });

  group('RunningController', () {
    test('loads summary and activities on initialization', () async {
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.summary.totalDistanceKm, 25.0);
      expect(controller.state.summary.weekDistanceKm, 10.0);
      expect(controller.state.activities, isEmpty);
    });

    test('logs manual run and updates state', () async {
      await Future<void>.delayed(Duration.zero);

      final success = await controller.logManualRun(
        distanceKm: 5.0,
        durationSeconds: 1800,
        title: 'Chạy buổi sáng',
      );

      expect(success, isTrue);
      expect(controller.state.activities.length, 1);
      expect(controller.state.activities.first.distanceKm, 5.0);
      expect(controller.state.activities.first.title, 'Chạy buổi sáng');
      expect(controller.state.summary.totalDistanceKm, 30.0);
      expect(controller.state.summary.totalRunsCount, 6);
    });

    test('deletes run activity and refreshes state', () async {
      await Future<void>.delayed(Duration.zero);

      await controller.logManualRun(distanceKm: 3.5, durationSeconds: 1200);
      expect(controller.state.activities.length, 1);

      final actId = controller.state.activities.first.id;
      final deleted = await controller.deleteRun(actId);

      expect(deleted, isTrue);
      expect(controller.state.activities, isEmpty);
    });
  });
}
