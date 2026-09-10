class ForumCategory {
  const ForumCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.order,
    required this.threadCount,
  });

  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int order;
  final int threadCount;

  factory ForumCategory.fromJson(Map<String, dynamic> json) {
    return ForumCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      order: json['order'] as int? ?? 0,
      threadCount: json['threadCount'] as int? ?? 0,
    );
  }
}

class ForumThread {
  const ForumThread({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.postCount,
    required this.createdAt,
    this.updatedAt,
    this.lastPostAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String content;
  final int viewCount;
  final int postCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastPostAt;

  factory ForumThread.fromJson(Map<String, dynamic> json) {
    return ForumThread(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Ẩn danh',
      authorAvatarUrl: json['authorAvatarUrl']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      viewCount: json['viewCount'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      lastPostAt: json['lastPostAt'] != null
          ? DateTime.tryParse(json['lastPostAt'].toString())
          : null,
    );
  }
}

class ForumPost {
  const ForumPost({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String threadId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id']?.toString() ?? '',
      threadId: json['threadId']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Ẩn danh',
      authorAvatarUrl: json['authorAvatarUrl']?.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
