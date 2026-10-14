import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/forum/data/models/forum_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final forumApiProvider = Provider<ForumApi>((ref) {
  return ForumApi(ref.watch(apiClientProvider));
});

class ForumApi {
  const ForumApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ForumCategory>> getCategories() async {
    final res = await _apiClient.get<List<dynamic>>('/forum/categories');
    return res
        .map((item) => ForumCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ForumThread>> getThreadsByCategory(String categoryId) async {
    final res = await _apiClient.get<List<dynamic>>(
      '/forum/categories/$categoryId/threads',
    );
    return res
        .map((item) => ForumThread.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ForumThread> getThread(String id) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/forum/threads/$id',
    );
    return ForumThread.fromJson(res);
  }

  Future<ForumThread> createThread({
    required String categoryId,
    required String title,
    required String content,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/forum/threads',
      data: {'categoryId': categoryId, 'title': title, 'content': content},
    );
    return ForumThread.fromJson(res);
  }

  Future<List<ForumPost>> getPosts(String threadId) async {
    final res = await _apiClient.get<List<dynamic>>(
      '/forum/threads/$threadId/posts',
    );
    return res
        .map((item) => ForumPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ForumPost> createPost({
    required String threadId,
    required String content,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/forum/posts',
      data: {'threadId': threadId, 'content': content},
    );
    return ForumPost.fromJson(res);
  }
}
