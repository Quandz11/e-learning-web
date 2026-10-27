import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunningActivity', () {
    test('parses from and to JSON correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'act-123',
        'userId': 'user-456',
        'distanceKm': 5.25,
        'durationSeconds': 1830,
        'paceMinPerKm': 5.81,
        'paceFormatted': "5'49\"/km",
        'caloriesBurned': 345,
        'activityDate': now.toIso8601String(),
        'title': 'Chạy ngoài trời công viên',
        'notes': 'Thời tiết đẹp, chạy thoải mái',
        'trackingMode': 'GPS',
        'createdAt': now.toIso8601String(),
      };

      final activity = RunningActivity.fromJson(json);

      expect(activity.id, 'act-123');
      expect(activity.userId, 'user-456');
      expect(activity.distanceKm, 5.25);
      expect(activity.durationSeconds, 1830);
      expect(activity.paceMinPerKm, 5.81);
      expect(activity.paceFormatted, "5'49\"/km");
      expect(activity.caloriesBurned, 345);
      expect(activity.title, 'Chạy ngoài trời công viên');
      expect(activity.notes, 'Thời tiết đẹp, chạy thoải mái');
      expect(activity.trackingMode, 'GPS');
      expect(activity.isGps, isTrue);
      expect(activity.durationFormatted, '30:30');

      final serialized = activity.toJson();
      expect(serialized['id'], 'act-123');
      expect(serialized['distanceKm'], 5.25);
      expect(serialized['durationSeconds'], 1830);
      expect(serialized['trackingMode'], 'GPS');
    });

    test('formats duration over 1 hour correctly', () {
      final activity = RunningActivity(
        id: 'act-2',
        userId: 'u-1',
        distanceKm: 12.0,
        durationSeconds: 4500, // 1h 15m
        paceFormatted: "6'15\"/km",
        caloriesBurned: 750,
        activityDate: DateTime.now(),
        title: 'Long run',
        trackingMode: 'GPS',
        createdAt: DateTime.now(),
      );

      expect(activity.durationFormatted, '1h 15m');
    });

    test('identifies manual tracking mode', () {
      final activity = RunningActivity(
        id: 'act-3',
        userId: 'u-1',
        distanceKm: 3.0,
        durationSeconds: 1200,
        paceFormatted: "6'40\"/km",
        caloriesBurned: 180,
        activityDate: DateTime.now(),
        title: 'Chạy máy',
        trackingMode: 'MANUAL',
        createdAt: DateTime.now(),
      );

      expect(activity.isGps, isFalse);
    });
  });

  group('RunningSummary', () {
    test('parses summary from JSON correctly', () {
      final json = {
        'totalDistanceKm': 48.75,
        'totalDurationSeconds': 17500,
        'totalCalories': 3200,
        'totalRunsCount': 8,
        'weekDistanceKm': 15.5,
        'monthDistanceKm': 35.0,
        'averagePaceMinPerKm': 5.95,
        'averagePaceFormatted': "5'57\"/km",
        'longestRunKm': 10.2,
        'currentStreakDays': 4,
      };

      final summary = RunningSummary.fromJson(json);

      expect(summary.totalDistanceKm, 48.75);
      expect(summary.totalDurationSeconds, 17500);
      expect(summary.totalCalories, 3200);
      expect(summary.totalRunsCount, 8);
      expect(summary.weekDistanceKm, 15.5);
      expect(summary.monthDistanceKm, 35.0);
      expect(summary.averagePaceFormatted, "5'57\"/km");
      expect(summary.longestRunKm, 10.2);
      expect(summary.currentStreakDays, 4);
      expect(summary.totalDurationFormatted, '4h 51m');
    });

    test('handles default empty summary safely', () {
      const summary = RunningSummary();
      expect(summary.totalDistanceKm, 0.0);
      expect(summary.totalDurationSeconds, 0);
      expect(summary.totalCalories, 0);
      expect(summary.totalRunsCount, 0);
      expect(summary.weekDistanceKm, 0.0);
      expect(summary.monthDistanceKm, 0.0);
      expect(summary.longestRunKm, 0.0);
      expect(summary.currentStreakDays, 0);
      expect(summary.totalDurationFormatted, '0 phút');
    });
  });

  group('CreateRunningActivityDto', () {
    test('serializes to JSON correctly', () {
      final now = DateTime.utc(2026, 10, 27, 8, 30);
      final dto = CreateRunningActivityDto(
        distanceKm: 5.5,
        durationSeconds: 1800,
        activityDate: now,
        title: 'Morning Run',
        notes: 'Good pace',
        trackingMode: 'GPS',
      );

      final json = dto.toJson();
      expect(json['distanceKm'], 5.5);
      expect(json['durationSeconds'], 1800);
      expect(json['activityDate'], now.toIso8601String());
      expect(json['title'], 'Morning Run');
      expect(json['notes'], 'Good pace');
      expect(json['trackingMode'], 'GPS');
    });
  });
}
