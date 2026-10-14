import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/articles/data/models/article_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final articlesApiProvider = Provider<ArticlesApi>((ref) {
  return ArticlesApi(ref.watch(apiClientProvider));
});

class ArticlesApi {
  const ArticlesApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ArticleSummary>> getArticles({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/articles',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final items = res['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => ArticleSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ArticleDetail> getArticleBySlug(String slug) async {
    final res = await _apiClient.get<Map<String, dynamic>>('/articles/$slug');
    return ArticleDetail.fromJson(res);
  }

  Future<List<ArticleSummary>> getArticlesByCategory(
    String categoryId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/articles/category/$categoryId',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final items = res['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => ArticleSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ArticleSummary>> searchArticles(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/articles/search',
      queryParameters: {'q': query, 'page': page, 'pageSize': pageSize},
    );
    final items = res['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => ArticleSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ArticleCategory>> getCategories() async {
    final res = await _apiClient.get<List<dynamic>>('/articles/categories');
    return res
        .map((item) => ArticleCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
