import 'package:e_learning_mobile/features/learning/data/models/offline_download_model.dart';
import 'package:e_learning_mobile/features/learning/data/services/offline_download_service.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/offline_download_controller.dart';
import 'package:e_learning_mobile/features/settings/presentation/screens/offline_downloads_screen.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOfflineDownloadService extends OfflineDownloadService {
  _FakeOfflineDownloadService(this.mockItems);

  final List<OfflineDownloadItem> mockItems;

  @override
  Future<List<OfflineDownloadItem>> getDownloadedItems() async {
    return mockItems;
  }

  @override
  Future<int> getTotalStorageUsed() async {
    var total = 0;
    for (final item in mockItems) {
      total += item.fileSizeBytes;
    }
    return total;
  }

  @override
  Future<void> deleteDownload(String id) async {
    mockItems.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> deleteAllDownloads() async {
    mockItems.clear();
  }
}

class _TestOfflineDownloadController extends OfflineDownloadController {
  _TestOfflineDownloadController(
    super.service,
    List<OfflineDownloadItem> items,
    int totalBytes,
  ) {
    state = OfflineDownloadState(
      items: items,
      totalStorageBytes: totalBytes,
      isLoading: false,
    );
  }

  @override
  Future<void> load() async {}
}

void main() {
  testWidgets(
    'OfflineDownloadsScreen shows empty state when no downloads exist',
    (tester) async {
      final fakeService = _FakeOfflineDownloadService([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineDownloadControllerProvider.overrideWith(
              (ref) => _TestOfflineDownloadController(fakeService, [], 0),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const OfflineDownloadsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nội Dung Đã Tải (Offline)'), findsOneWidget);
      expect(find.text('0 B'), findsOneWidget);
      expect(
        find.textContaining('Chưa có video hoặc tài liệu nào được tải về'),
        findsOneWidget,
      );
    },
  );

  testWidgets('OfflineDownloadsScreen lists downloaded items correctly', (
    tester,
  ) async {
    final sampleItem = OfflineDownloadItem(
      id: 'part-123',
      courseId: 'course-1',
      courseTitle: 'Khóa học Nhịn ăn Căn bản',
      title: 'Bài 1: Lý thuyết thực hành',
      type: OfflineDownloadType.video,
      remoteUrl: 'https://example.com/v.mp4',
      localPath: '/tmp/v.mp4',
      fileSizeBytes: 20971520, // ~20 MB
      downloadedAt: DateTime(2026, 9, 13),
    );

    final fakeService = _FakeOfflineDownloadService([sampleItem]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineDownloadControllerProvider.overrideWith(
            (ref) => _TestOfflineDownloadController(fakeService, [
              sampleItem,
            ], 20971520),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OfflineDownloadsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('20.0 MB'), findsWidgets);
    expect(find.text('Bài 1: Lý thuyết thực hành'), findsOneWidget);
    expect(find.text('Khóa học Nhịn ăn Căn bản'), findsOneWidget);
    expect(find.text('Video • 20.0 MB'), findsOneWidget);
  });

  test('formatBytes formats file sizes accurately', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(1048576 * 25), '25.0 MB');
    expect(formatBytes(1073741824 * 2), '2.00 GB');
  });
}
