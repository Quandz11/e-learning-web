import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:e_learning_mobile/features/learning/data/models/offline_download_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final offlineDownloadServiceProvider = Provider<OfflineDownloadService>((ref) {
  return OfflineDownloadService(dio: Dio());
});

class OfflineDownloadService {
  OfflineDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _storageKey = 'offline_downloads_registry_v1';

  Future<String> _getOfflineDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${dir.path}/offline_media');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return offlineDir.path;
  }

  Future<List<OfflineDownloadItem>> getDownloadedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      final items = <OfflineDownloadItem>[];
      for (final json in list) {
        final item = OfflineDownloadItem.fromMap(json as Map<String, dynamic>);
        final file = File(item.localPath);
        if (await file.exists()) {
          final size = await file.length();
          // Filter out corrupted/HTML files (< 50 KB)
          if (item.isVideo && size < 50000) {
            await file.delete();
            continue;
          }
          items.add(item);
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<OfflineDownloadItem?> getItem(String id) async {
    final items = await getDownloadedItems();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<bool> isDownloaded(String id) async {
    final item = await getItem(id);
    return item != null;
  }

  Future<OfflineDownloadItem> download({
    required String id,
    required String courseId,
    required String courseTitle,
    required String title,
    required OfflineDownloadType type,
    required String remoteUrl,
    void Function(double progress)? onProgress,
  }) async {
    final baseDir = await _getOfflineDirectoryPath();
    final ext = type == OfflineDownloadType.video ? 'mp4' : 'pdf';
    final savePath = '$baseDir/${type.name}_$id.$ext';

    final headers = <String, String>{
      'Referer': 'https://iframe.mediadelivery.net/',
      'Origin': 'https://iframe.mediadelivery.net',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };

    var downloadUrl = remoteUrl;
    if (type == OfflineDownloadType.video &&
        remoteUrl.contains('mediadelivery.net')) {
      try {
        final res = await _dio.get<String>(
          remoteUrl,
          options: Options(
            headers: headers,
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
        final html = res.data ?? '';
        final match =
            RegExp(r'content="([^"]+\/play_[^"]+\.mp4[^"]*)"').firstMatch(html) ??
            RegExp(r'content="([^"]+\.mp4[^"]*)"').firstMatch(html);
        if (match != null && match.group(1) != null) {
          downloadUrl = match.group(1)!;
        }
      } catch (_) {
        // Fallback to original remoteUrl
      }
    }

    await _dio.download(
      downloadUrl,
      savePath,
      options: Options(headers: headers),
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    final file = File(savePath);
    final size = await file.length();

    if (type == OfflineDownloadType.video && size < 50000) {
      if (await file.exists()) await file.delete();
      throw Exception(
        'Nội dung video này là trình phát trực tuyến, không hỗ trợ lưu tệp offline.',
      );
    }

    final newItem = OfflineDownloadItem(
      id: id,
      courseId: courseId,
      courseTitle: courseTitle,
      title: title,
      type: type,
      remoteUrl: remoteUrl,
      localPath: savePath,
      fileSizeBytes: size,
      downloadedAt: DateTime.now(),
    );

    final currentItems = await getDownloadedItems();
    final updated = currentItems.where((i) => i.id != id).toList()
      ..add(newItem);
    await _saveRegistry(updated);

    return newItem;
  }

  Future<void> deleteDownload(String id) async {
    final item = await getItem(id);
    if (item != null) {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    final currentItems = await getDownloadedItems();
    final updated = currentItems.where((i) => i.id != id).toList();
    await _saveRegistry(updated);
  }

  Future<void> deleteAllDownloads() async {
    final items = await getDownloadedItems();
    for (final item in items) {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _saveRegistry([]);
  }

  Future<int> getTotalStorageUsed() async {
    final items = await getDownloadedItems();
    var total = 0;
    for (final item in items) {
      total += item.fileSizeBytes;
    }
    return total;
  }

  Future<void> _saveRegistry(List<OfflineDownloadItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((i) => i.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
