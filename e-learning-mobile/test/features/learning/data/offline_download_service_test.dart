import 'package:e_learning_mobile/features/learning/data/models/offline_download_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflineDownloadItem & Model Tests', () {
    test('OfflineDownloadItem serializes and deserializes correctly', () {
      final now = DateTime(2026, 9, 13, 10, 0, 0);
      final item = OfflineDownloadItem(
        id: 'lesson-part-1',
        courseId: 'course-101',
        courseTitle: 'Khóa học Nhịn ăn Căn bản',
        title: 'Bài 1: Tổng quan nhịn ăn',
        type: OfflineDownloadType.video,
        remoteUrl: 'https://example.com/video.mp4',
        localPath: '/storage/offline/video.mp4',
        fileSizeBytes: 15485760,
        downloadedAt: now,
      );

      final map = item.toMap();
      expect(map['id'], 'lesson-part-1');
      expect(map['type'], 'video');
      expect(map['fileSizeBytes'], 15485760);

      final restored = OfflineDownloadItem.fromMap(map);
      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.isVideo, isTrue);
      expect(restored.isDocument, isFalse);
      expect(restored.fileSizeBytes, 15485760);
    });

    test('OfflineDownloadItem handles document type correctly', () {
      final item = OfflineDownloadItem(
        id: 'doc-part-2',
        courseId: 'course-101',
        courseTitle: 'Khóa học Nhịn ăn Căn bản',
        title: 'Tài liệu hướng dẫn PDF',
        type: OfflineDownloadType.document,
        remoteUrl: 'https://example.com/guide.pdf',
        localPath: '/storage/offline/doc.pdf',
        fileSizeBytes: 2048576,
        downloadedAt: DateTime.now(),
      );

      final map = item.toMap();
      expect(map['type'], 'document');

      final restored = OfflineDownloadItem.fromMap(map);
      expect(restored.isDocument, isTrue);
      expect(restored.isVideo, isFalse);
    });
  });
}
