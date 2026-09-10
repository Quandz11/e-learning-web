import 'package:e_learning_mobile/core/network/cache_service.dart';
import 'package:e_learning_mobile/features/articles/data/articles_api.dart';
import 'package:e_learning_mobile/features/articles/data/models/article_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final articlesRepositoryProvider = Provider<ArticlesRepository>((ref) {
  return ArticlesRepository(
    ref.watch(articlesApiProvider),
    ref.watch(cacheServiceProvider),
  );
});

class ArticlesRepository {
  ArticlesRepository(this._api, this._cacheService);

  final ArticlesApi _api;
  final CacheService _cacheService;
  static const String _categoriesCacheKey = 'articles_categories';

  Future<List<ArticleCategory>> getCategories() async {
    final cached = await _cacheService.getList(_categoriesCacheKey);
    if (cached != null) {
      try {
        return cached
            .map((e) => ArticleCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    final categories = await _api.getCategories();
    await _cacheService.set(
      _categoriesCacheKey,
      categories.map((c) => {
        'id': c.id,
        'name': c.name,
        'slug': c.slug,
        'description': c.description,
        'articleCount': c.articleCount,
      }).toList(),
    );
    return categories;
  }

  Future<List<ArticleSummary>> getArticles({
    String? categoryId,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (query != null && query.trim().isNotEmpty) {
      return _api.searchArticles(query.trim(), page: page, pageSize: pageSize);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      return _api.getArticlesByCategory(categoryId, page: page, pageSize: pageSize);
    }
    return _api.getArticles(page: page, pageSize: pageSize);
  }

  Future<ArticleDetail> getArticleBySlug(String slug) async {
    return _api.getArticleBySlug(slug);
  }
}
