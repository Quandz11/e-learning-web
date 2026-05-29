import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../models/forum_models.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository(ref.read(apiClientProvider));
});

class ForumRepository {
  ForumRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ForumCategoryModel>> getCategories() async {
    final data = await _apiClient.get<List<dynamic>>('/forum/categories');
    return data
        .whereType<Map<String, dynamic>>()
        .map(ForumCategoryModel.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getThreadsByCategory(
    String categoryId,
  ) async {
    final data = await _apiClient.get<List<dynamic>>(
      '/forum/categories/$categoryId/threads',
    );
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> getThreadDetail(String threadId) async {
    return _apiClient.get<Map<String, dynamic>>('/forum/threads/$threadId');
  }

  Future<List<Map<String, dynamic>>> getPostsByThread(String threadId) async {
    final data = await _apiClient.get<List<dynamic>>(
      '/forum/threads/$threadId/posts',
    );
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> createThread(Map<String, dynamic> payload) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/forum/threads',
      data: payload,
    );
  }

  Future<void> createPost(Map<String, dynamic> payload) async {
    await _apiClient.post<Map<String, dynamic>>('/forum/posts', data: payload);
  }

  Future<void> updateThread(
    String threadId,
    Map<String, dynamic> payload,
  ) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/forum/threads/$threadId',
      data: payload,
    );
  }

  Future<void> deleteThread(String threadId) async {
    await _apiClient.delete<Map<String, dynamic>>('/forum/threads/$threadId');
  }

  Future<void> updatePost(String postId, Map<String, dynamic> payload) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/forum/posts/$postId',
      data: payload,
    );
  }

  Future<void> deletePost(String postId) async {
    await _apiClient.delete<Map<String, dynamic>>('/forum/posts/$postId');
  }
}
