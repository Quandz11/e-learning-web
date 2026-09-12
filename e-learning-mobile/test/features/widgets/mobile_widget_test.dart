import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_learning_mobile/features/widgets/domain/mobile_widget_models.dart';
import 'package:e_learning_mobile/core/services/home_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileWidgetStateData & HomeWidgetService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('MobileWidgetStateData default values and goal progress calculation', () {
      final defaultData = MobileWidgetStateData.defaultData();
      expect(defaultData.streakDays, 7);
      expect(defaultData.targetMinutes, 30);
      expect(defaultData.learnedMinutes, 25);
      expect(defaultData.goalProgressRatio, closeTo(25 / 30, 0.01));
    });

    test('MobileWidgetStateData fromMap and toMap conversion', () {
      final map = {
        'streakDays': 12,
        'targetMinutes': 40,
        'learnedMinutes': 40,
        'activeCourseTitle': 'Lập trình Dart cơ bản',
        'activeCourseProgress': 90,
        'nextLessonTitle': 'Bài 10: Final Project',
        'nextReminderTime': '21:00',
      };

      final state = MobileWidgetStateData.fromMap(map);
      expect(state.streakDays, 12);
      expect(state.activeCourseTitle, 'Lập trình Dart cơ bản');
      expect(state.goalProgressRatio, 1.0);

      final exported = state.toMap();
      expect(exported['streakDays'], 12);
      expect(exported['activeCourseProgress'], 90);
    });

    test('HomeWidgetService update and get widget data', () async {
      final service = HomeWidgetService.instance;
      final result = await service.updateWidgetData(
        streakDays: 15,
        targetMinutes: 45,
        learnedMinutes: 30,
        activeCourseTitle: 'Khoá học AI Fundamentals',
        activeCourseProgress: 50,
        nextLessonTitle: 'Bài 3: Prompt Engineering',
        nextReminderTime: '19:30',
      );

      expect(result, isTrue);

      final data = await service.getWidgetData();
      expect(data['streakDays'], 15);
      expect(data['activeCourseTitle'], 'Khoá học AI Fundamentals');
      expect(data['nextReminderTime'], '19:30');
    });
  });
}
