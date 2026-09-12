class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    this.content,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? content;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseUtcToLocal(json['createdAt']?.toString()),
    );
  }

  static DateTime _parseUtcToLocal(String? rawStr) {
    if (rawStr == null || rawStr.isEmpty) return DateTime.now();
    var str = rawStr.trim();
    if (!str.endsWith('Z') && !str.contains('+') && !str.contains('-')) {
      str = '${str}Z';
    }
    final dt = DateTime.tryParse(str) ?? DateTime.now();
    return dt.toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationsPayload {
  const NotificationsPayload({
    required this.notifications,
    required this.unreadCount,
  });

  final List<NotificationItem> notifications;
  final int unreadCount;

  factory NotificationsPayload.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'];
    final notificationsList = <NotificationItem>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          notificationsList.add(NotificationItem.fromJson(item));
        } else if (item is Map) {
          notificationsList.add(
            NotificationItem.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    return NotificationsPayload(
      notifications: notificationsList,
      unreadCount: json['unreadCount'] as int? ??
          notificationsList.where((n) => !n.isRead).length,
    );
  }
}
