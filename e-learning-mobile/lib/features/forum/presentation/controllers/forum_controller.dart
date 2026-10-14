import 'package:e_learning_mobile/features/forum/data/forum_repository.dart';
import 'package:e_learning_mobile/features/forum/data/models/forum_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForumState {
  const ForumState({
    required this.categories,
    required this.threads,
    this.selectedCategoryId,
    this.isLoading = false,
    this.error,
  });

  final List<ForumCategory> categories;
  final List<ForumThread> threads;
  final String? selectedCategoryId;
  final bool isLoading;
  final String? error;

  ForumState copyWith({
    List<ForumCategory>? categories,
    List<ForumThread>? threads,
    String? selectedCategoryId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ForumState(
      categories: categories ?? this.categories,
      threads: threads ?? this.threads,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final forumControllerProvider =
    StateNotifierProvider<ForumController, ForumState>((ref) {
      return ForumController(ref.watch(forumRepositoryProvider));
    });

final forumThreadDetailProvider = FutureProvider.family<ForumThread, String>((
  ref,
  threadId,
) async {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.getThread(threadId);
});

final forumThreadPostsProvider = FutureProvider.family<List<ForumPost>, String>(
  (ref, threadId) async {
    final repo = ref.watch(forumRepositoryProvider);
    return repo.getPosts(threadId);
  },
);

class ForumController extends StateNotifier<ForumState> {
  ForumController(this._repository)
    : super(const ForumState(categories: [], threads: [], isLoading: true)) {
    load();
  }

  final ForumRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _repository.getCategories();
      String? activeCatId = state.selectedCategoryId;
      if (activeCatId == null && categories.isNotEmpty) {
        activeCatId = categories.first.id;
      }

      List<ForumThread> threads = [];
      if (activeCatId != null) {
        threads = await _repository.getThreadsByCategory(activeCatId);
      }

      state = state.copyWith(
        categories: categories,
        selectedCategoryId: activeCatId,
        threads: threads,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectCategory(String categoryId) async {
    if (state.selectedCategoryId == categoryId) return;
    state = state.copyWith(
      selectedCategoryId: categoryId,
      isLoading: true,
      clearError: true,
    );
    try {
      final threads = await _repository.getThreadsByCategory(categoryId);
      state = state.copyWith(threads: threads, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    if (state.selectedCategoryId != null) {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final threads = await _repository.getThreadsByCategory(
          state.selectedCategoryId!,
        );
        state = state.copyWith(threads: threads, isLoading: false);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } else {
      await load();
    }
  }
}
