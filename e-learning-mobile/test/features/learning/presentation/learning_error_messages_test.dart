import 'package:e_learning_mobile/features/learning/presentation/learning_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stripHtml removes tags and decodes common entities', () {
    expect(
      stripHtml('Cải&nbsp;thiện&nbsp;tiêu&nbsp;hóa &amp; ngủ <b>sâu</b>'),
      'Cải thiện tiêu hóa & ngủ sâu',
    );
  });

  test('formatLearningDuration formats minute and hour durations', () {
    expect(formatLearningDuration(const Duration(seconds: 65)), '1:05');
    expect(formatLearningDuration(const Duration(seconds: 3661)), '1:01:01');
  });
}
