class ArticleSummary {
  const ArticleSummary({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.featuredImageUrl,
    this.categoryName,
    this.authorName,
    required this.viewCount,
    this.publishedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? featuredImageUrl;
  final String? categoryName;
  final String? authorName;
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime createdAt;

  factory ArticleSummary.fromJson(Map<String, dynamic> json) {
    return ArticleSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      excerpt: json['excerpt']?.toString(),
      featuredImageUrl: json['featuredImageUrl']?.toString(),
      categoryName: json['categoryName']?.toString(),
      authorName: json['authorName']?.toString(),
      viewCount: json['viewCount'] as int? ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ArticleDetail {
  const ArticleDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.excerpt,
    this.featuredImageUrl,
    this.categoryId,
    this.categoryName,
    this.authorName,
    required this.viewCount,
    this.publishedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String slug;
  final String content;
  final String? excerpt;
  final String? featuredImageUrl;
  final String? categoryId;
  final String? categoryName;
  final String? authorName;
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime createdAt;

  factory ArticleDetail.fromJson(Map<String, dynamic> json) {
    return ArticleDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      excerpt: json['excerpt']?.toString(),
      featuredImageUrl: json['featuredImageUrl']?.toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      authorName: json['authorName']?.toString(),
      viewCount: json['viewCount'] as int? ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ArticleCategory {
  const ArticleCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.articleCount,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final int articleCount;

  factory ArticleCategory.fromJson(Map<String, dynamic> json) {
    return ArticleCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      articleCount: json['articleCount'] as int? ?? 0,
    );
  }
}
