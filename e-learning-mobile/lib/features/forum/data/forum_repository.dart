import 'package:e_learning_mobile/core/network/cache_service.dart';
import 'package:e_learning_mobile/features/forum/data/forum_api.dart';
import 'package:e_learning_mobile/features/forum/data/models/forum_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository(
    ref.watch(forumApiProvider),
    ref.watch(cacheServiceProvider),
  );
});

class ForumRepository {
  ForumRepository(this._api, this._cacheService);

  final ForumApi _api;
  final CacheService _cacheService;
  static const String _categoriesCacheKey = 'forum_categories';

  Future<List<ForumCategory>> getCategories() async {
    final cached = await _cacheService.getList(_categoriesCacheKey);
    if (cached != null) {
      try {
        return cached
            .map((e) => ForumCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    final categories = await _api.getCategories();
    await _cacheService.set(
      _categoriesCacheKey,
      categories.map((c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'icon': c.icon,
        'order': c.order,
        'threadCount': c.threadCount,
      }).toList(),
    );
    return categories;
  }

  Future<List<ForumThread>> getThreadsByCategory(String categoryId) async {
    return _api.getThreadsByCategory(categoryId);
  }

  Future<ForumThread> getThread(String id) async {
    return _api.getThread(id);
  }

  Future<ForumThread> createThread({
    required String categoryId,
    required String title,
    required String content,
  }) async {
    return _api.createThread(
      categoryId: categoryId,
      title: title,
      content: content,
    );
  }

  Future<List<ForumPost>> getPosts(String threadId) async {
    return _api.getPosts(threadId);
  }

  Future<ForumPost> createPost({
    required String threadId,
    required String content,
  }) async {
    return _api.createPost(threadId: threadId, content: content);
  }
}
