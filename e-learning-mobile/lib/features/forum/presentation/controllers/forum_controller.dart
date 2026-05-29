import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/telemetry/app_logger.dart';
import '../../data/models/forum_models.dart';
import '../../data/repositories/forum_repository.dart';

const _unset = Object();

@immutable
class ForumState {
  const ForumState({
    this.loading = false,
    this.submitting = false,
    this.error,
    this.categories = const [],
    this.selectedCategoryId,
    this.threads = const [],
    this.selectedThreadId,
    this.selectedThread,
    this.posts = const [],
  });

  final bool loading;
  final bool submitting;
  final String? error;
  final List<ForumCategoryModel> categories;
  final String? selectedCategoryId;
  final List<Map<String, dynamic>> threads;
  final String? selectedThreadId;
  final Map<String, dynamic>? selectedThread;
  final List<Map<String, dynamic>> posts;

  ForumState copyWith({
    bool? loading,
    bool? submitting,
    Object? error = _unset,
    List<ForumCategoryModel>? categories,
    Object? selectedCategoryId = _unset,
    List<Map<String, dynamic>>? threads,
    Object? selectedThreadId = _unset,
    Object? selectedThread = _unset,
    List<Map<String, dynamic>>? posts,
  }) {
    return ForumState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: identical(error, _unset) ? this.error : error as String?,
      categories: categories ?? this.categories,
      selectedCategoryId: identical(selectedCategoryId, _unset)
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      threads: threads ?? this.threads,
      selectedThreadId: identical(selectedThreadId, _unset)
          ? this.selectedThreadId
          : selectedThreadId as String?,
      selectedThread: identical(selectedThread, _unset)
          ? this.selectedThread
          : selectedThread as Map<String, dynamic>?,
      posts: posts ?? this.posts,
    );
  }
}

final forumControllerProvider =
    StateNotifierProvider.autoDispose<ForumController, ForumState>((ref) {
      final controller = ForumController(
        repository: ref.read(forumRepositoryProvider),
        logger: ref.read(appLoggerProvider),
      );
      return controller;
    });

class ForumController extends StateNotifier<ForumState> {
  ForumController({required this.repository, required this.logger})
    : super(const ForumState());

  final ForumRepository repository;
  final AppLogger logger;

  Future<void> initialize() async {
    await refreshCategories();
  }

  Future<void> refreshCategories() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final categories = await repository.getCategories();
      String? selectedCategoryId = state.selectedCategoryId;
      if (categories.isNotEmpty) {
        final hasSelectedCategory =
            selectedCategoryId != null &&
            categories.any((category) => category.id == selectedCategoryId);
        selectedCategoryId = hasSelectedCategory
            ? selectedCategoryId
            : categories.first.id;
      } else {
        selectedCategoryId = null;
      }

      state = state.copyWith(
        loading: false,
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        threads: const [],
        selectedThreadId: null,
        selectedThread: null,
        posts: const [],
      );

      if (selectedCategoryId != null) {
        await loadThreads(selectedCategoryId);
      }
    } catch (error, stackTrace) {
      logger.error('Failed to load forum categories', error, stackTrace);
      state = state.copyWith(
        loading: false,
        error: 'Failed to load forum categories: $error',
      );
    }
  }

  Future<void> selectCategory(String categoryId) async {
    if (categoryId.isEmpty || state.selectedCategoryId == categoryId) {
      return;
    }

    state = state.copyWith(
      selectedCategoryId: categoryId,
      selectedThreadId: null,
      selectedThread: null,
      posts: const [],
      error: null,
    );
    await loadThreads(categoryId);
  }

  Future<void> loadThreads(String categoryId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final threads = _normalizeMapList(
        await repository.getThreadsByCategory(categoryId),
      );

      state = state.copyWith(loading: false, threads: threads);
    } catch (error, stackTrace) {
      logger.error('Failed to load forum threads', error, stackTrace);
      state = state.copyWith(
        loading: false,
        error: 'Failed to load threads: $error',
      );
    }
  }

  Future<void> openThread(String threadId) async {
    if (threadId.isEmpty) {
      return;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait<dynamic>([
        repository.getThreadDetail(threadId),
        repository.getPostsByThread(threadId),
      ]);
      final threadDetail = _normalizeMap(results[0]);
      final posts = _normalizeMapList(results[1]);

      state = state.copyWith(
        loading: false,
        selectedThreadId: threadId,
        selectedThread: threadDetail,
        posts: posts,
      );
    } catch (error, stackTrace) {
      logger.error('Failed to load thread detail', error, stackTrace);
      state = state.copyWith(
        loading: false,
        error: 'Failed to load thread detail: $error',
      );
    }
  }

  Future<void> createThread({
    required String categoryId,
    required String title,
    required String content,
  }) async {
    if (categoryId.isEmpty) {
      state = state.copyWith(error: 'Please select a category first.');
      return;
    }

    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();
    if (normalizedTitle.isEmpty || normalizedContent.isEmpty) {
      state = state.copyWith(error: 'Title and content are required.');
      return;
    }

    state = state.copyWith(submitting: true, error: null);
    try {
      await repository.createThread({
        'categoryId': categoryId,
        'title': normalizedTitle,
        'content': normalizedContent,
      });
      await loadThreads(categoryId);
    } catch (error, stackTrace) {
      logger.error('Failed to create thread', error, stackTrace);
      state = state.copyWith(error: 'Create thread failed: $error');
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<void> updateThread({
    required String threadId,
    required String title,
    required String content,
  }) async {
    if (threadId.isEmpty) {
      return;
    }

    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();
    if (normalizedTitle.isEmpty || normalizedContent.isEmpty) {
      state = state.copyWith(error: 'Title and content are required.');
      return;
    }

    state = state.copyWith(submitting: true, error: null);
    try {
      await repository.updateThread(threadId, {
        'title': normalizedTitle,
        'content': normalizedContent,
      });

      final categoryId = state.selectedCategoryId;
      if (categoryId != null) {
        await loadThreads(categoryId);
      }
      await openThread(threadId);
    } catch (error, stackTrace) {
      logger.error('Failed to update thread', error, stackTrace);
      state = state.copyWith(error: 'Update thread failed: $error');
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<void> deleteThread(String threadId) async {
    if (threadId.isEmpty) {
      return;
    }

    state = state.copyWith(submitting: true, error: null);
    try {
      await repository.deleteThread(threadId);

      final categoryId = state.selectedCategoryId;
      if (categoryId != null) {
        await loadThreads(categoryId);
      }

      if (state.selectedThreadId == threadId) {
        state = state.copyWith(
          selectedThreadId: null,
          selectedThread: null,
          posts: const [],
        );
      }
    } catch (error, stackTrace) {
      logger.error('Failed to delete thread', error, stackTrace);
      state = state.copyWith(error: 'Delete thread failed: $error');
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<void> createPost({
    required String threadId,
    required String content,
  }) async {
    if (threadId.isEmpty) {
      return;
    }

    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      state = state.copyWith(error: 'Reply content is required.');
      return;
    }

    state = state.copyWith(submitting: true, error: null);
    try {
      await repository.createPost({
        'threadId': threadId,
        'content': normalizedContent,
      });
      await openThread(threadId);
    } catch (error, stackTrace) {
      logger.error('Failed to create post', error, stackTrace);
      state = state.copyWith(error: 'Create post failed: $error');
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<void> updatePost({
    required String postId,
    required String threadId,
    required String content,
  }) async {
    if (postId.isEmpty || threadId.isEmpty) {
      return;
    }

    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      state = state.copyWith(error: 'Reply content is required.');
      return;
    }

    state = state.copyWith(submitting: true, error: null);
    try {
      await repository.updatePost(postId, {'content': normalizedContent});
      await openThread(threadId);
    } catch (error, stackTrace) {
      logger.error('Failed to update post', error, stackTrace);
      state = state.copyWith(error: 'Update post failed: $error');
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  Future<void> deletePost({
    required String postId,
    required String threadId,
  }) async {
    if (postId.isEmpty || threadId.isEmpty) {
      return;
    }

    state = state.copyWith(submitting: true, error: null);
    try {
      await repository.deletePost(postId);
      await openThread(threadId);
    } catch (error, stackTrace) {
      logger.error('Failed to delete post', error, stackTrace);
      state = state.copyWith(error: 'Delete post failed: $error');
    } finally {
      state = state.copyWith(submitting: false);
    }
  }

  List<Map<String, dynamic>> _normalizeMapList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => _normalizeMap(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _normalizeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    return <String, dynamic>{};
  }
}
