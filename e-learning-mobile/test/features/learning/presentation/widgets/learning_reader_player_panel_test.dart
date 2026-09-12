import 'package:e_learning_mobile/features/learning/presentation/widgets/document_reader_panel.dart';
import 'package:e_learning_mobile/features/learning/presentation/widgets/media_player_panel.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_course_detail_repository.dart';

void main() {
  testWidgets('media panel passes backend playback url to player builder', (
    tester,
  ) async {
    Uri? capturedUrl;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningMediaPlayerBuilderProvider.overrideWithValue(({
            required url,
            required title,
            required duration,
            embedUrl,
            videoId,
          }) {
            capturedUrl = url;
            return Text('Fake player: $title');
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: MediaPlayerPanel(part: fakeLessonPart())),
        ),
      ),
    );

    expect(find.text('Fake player: ${fakeLessonPart().title}'), findsOneWidget);
    expect(capturedUrl, Uri.parse('https://video.example.com/play.m3u8'));
  });

  testWidgets('media panel handles invalid playback url safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MediaPlayerPanel(part: fakeLessonPart(playbackUrl: null)),
        ),
      ),
    );

    expect(
      find.textContaining('Video chưa có đường dẫn phát hợp lệ'),
      findsOneWidget,
    );
  });

  testWidgets('document panel passes backend document url to reader builder', (
    tester,
  ) async {
    Uri? capturedUrl;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentReaderBuilderProvider.overrideWithValue(({
            required url,
            required title,
            controller,
            onDocumentLoaded,
            onPageChanged,
          }) {
            capturedUrl = url;
            return Text('Fake reader: $title');
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: DocumentReaderPanel(part: fakeDocumentPart())),
        ),
      ),
    );

    expect(find.text('Fake reader: guide.pdf'), findsOneWidget);
    expect(
      capturedUrl,
      Uri.parse('https://cdn.example.com/documents/guide.pdf'),
    );
  });

  testWidgets('document panel handles invalid document url safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DocumentReaderPanel(part: fakeDocumentPart(documentUrl: null)),
        ),
      ),
    );

    expect(
      find.textContaining('Tài liệu chưa có đường dẫn hợp lệ'),
      findsOneWidget,
    );
  });
}
