import 'package:e_learning_mobile/features/learning/data/models/offline_download_model.dart';
import 'package:e_learning_mobile/features/learning/data/services/offline_download_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineDownloadState {
  const OfflineDownloadState({
    this.items = const [],
    this.downloadProgress = const {},
    this.isLoading = false,
    this.totalStorageBytes = 0,
  });

  final List<OfflineDownloadItem> items;
  final Map<String, double> downloadProgress;
  final bool isLoading;
  final int totalStorageBytes;

  bool isDownloaded(String id) => items.any((i) => i.id == id);
  bool isDownloading(String id) => downloadProgress.containsKey(id);
  double? getProgress(String id) => downloadProgress[id];

  OfflineDownloadItem? getItem(String id) {
    try {
      return items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  OfflineDownloadState copyWith({
    List<OfflineDownloadItem>? items,
    Map<String, double>? downloadProgress,
    bool? isLoading,
    int? totalStorageBytes,
  }) {
    return OfflineDownloadState(
      items: items ?? this.items,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isLoading: isLoading ?? this.isLoading,
      totalStorageBytes: totalStorageBytes ?? this.totalStorageBytes,
    );
  }
}

class OfflineDownloadController extends StateNotifier<OfflineDownloadState> {
  OfflineDownloadController(this._service)
    : super(const OfflineDownloadState()) {
    load();
  }

  final OfflineDownloadService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final items = await _service.getDownloadedItems();
    final total = await _service.getTotalStorageUsed();
    state = state.copyWith(
      items: items,
      totalStorageBytes: total,
      isLoading: false,
    );
  }

  Future<bool> startDownload({
    required String id,
    required String courseId,
    required String courseTitle,
    required String title,
    required OfflineDownloadType type,
    required String remoteUrl,
  }) async {
    if (state.isDownloading(id) || state.isDownloaded(id)) return false;

    final updatedProgress = Map<String, double>.from(state.downloadProgress);
    updatedProgress[id] = 0.0;
    state = state.copyWith(downloadProgress: updatedProgress);

    var lastReported = 0.0;
    try {
      await _service.download(
        id: id,
        courseId: courseId,
        courseTitle: courseTitle,
        title: title,
        type: type,
        remoteUrl: remoteUrl,
        onProgress: (prog) {
          if ((prog - lastReported).abs() >= 0.01 || prog >= 1.0) {
            lastReported = prog;
            final pMap = Map<String, double>.from(state.downloadProgress);
            pMap[id] = prog;
            state = state.copyWith(downloadProgress: pMap);
          }
        },
      );

      final pMap = Map<String, double>.from(state.downloadProgress)..remove(id);
      state = state.copyWith(downloadProgress: pMap);
      await load();
      return true;
    } catch (e, stack) {
      debugPrint('[OfflineDownload] Download error: $e\n$stack');
      final pMap = Map<String, double>.from(state.downloadProgress)..remove(id);
      state = state.copyWith(downloadProgress: pMap);
      return false;
    }
  }

  Future<void> deleteDownload(String id) async {
    await _service.deleteDownload(id);
    await load();
  }

  Future<void> deleteAll() async {
    await _service.deleteAllDownloads();
    await load();
  }
}

final offlineDownloadControllerProvider =
    StateNotifierProvider<OfflineDownloadController, OfflineDownloadState>((
      ref,
    ) {
      final service = ref.watch(offlineDownloadServiceProvider);
      return OfflineDownloadController(service);
    });
