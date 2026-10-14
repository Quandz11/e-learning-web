import 'package:e_learning_mobile/features/articles/data/articles_repository.dart';
import 'package:e_learning_mobile/features/articles/data/models/article_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArticlesState {
  const ArticlesState({
    required this.articles,
    required this.categories,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<ArticleSummary> articles;
  final List<ArticleCategory> categories;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  ArticlesState copyWith({
    List<ArticleSummary>? articles,
    List<ArticleCategory>? categories,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ArticlesState(
      articles: articles ?? this.articles,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final articlesControllerProvider =
    StateNotifierProvider<ArticlesController, ArticlesState>((ref) {
      return ArticlesController(ref.watch(articlesRepositoryProvider));
    });

final articleDetailProvider = FutureProvider.family<ArticleDetail, String>((
  ref,
  slug,
) async {
  final repo = ref.watch(articlesRepositoryProvider);
  return repo.getArticleBySlug(slug);
});

class ArticlesController extends StateNotifier<ArticlesState> {
  ArticlesController(this._repository)
    : super(
        const ArticlesState(articles: [], categories: [], isLoading: true),
      ) {
    load();
  }

  final ArticlesRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _repository.getCategories();
      final articles = await _repository.getArticles(
        categoryId: state.selectedCategoryId,
        query: state.searchQuery,
      );
      state = state.copyWith(
        categories: categories,
        articles: articles,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectCategory(String? categoryId) async {
    if (state.selectedCategoryId == categoryId) return;
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      isLoading: true,
      clearError: true,
    );
    try {
      final articles = await _repository.getArticles(
        categoryId: categoryId,
        query: state.searchQuery,
      );
      state = state.copyWith(articles: articles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      clearError: true,
    );
    try {
      final articles = await _repository.getArticles(
        categoryId: state.selectedCategoryId,
        query: query,
      );
      state = state.copyWith(articles: articles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await load();
  }
}
