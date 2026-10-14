enum OfflineDownloadType { video, document }

class OfflineDownloadItem {
  const OfflineDownloadItem({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.type,
    required this.remoteUrl,
    required this.localPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String title;
  final OfflineDownloadType type;
  final String remoteUrl;
  final String localPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;

  bool get isVideo => type == OfflineDownloadType.video;
  bool get isDocument => type == OfflineDownloadType.document;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'title': title,
      'type': type.name,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory OfflineDownloadItem.fromMap(Map<String, dynamic> map) {
    return OfflineDownloadItem(
      id: map['id'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: (map['type'] as String?) == 'document'
          ? OfflineDownloadType.document
          : OfflineDownloadType.video,
      remoteUrl: map['remoteUrl'] as String? ?? '',
      localPath: map['localPath'] as String? ?? '',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      downloadedAt:
          DateTime.tryParse(map['downloadedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
