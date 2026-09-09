import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/home/data/home_repository.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController(ref.read(homeRepositoryProvider));
  },
);

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._repository) : super(const HomeState());

  final HomeRepository _repository;

  Future<void> ensureLoaded() async {
    if (state.status != HomeStatus.initial) {
      return;
    }
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    if (state.isRefreshing || state.isInitialLoading) {
      return;
    }

    if (refresh && state.status == HomeStatus.success) {
      state = state.copyWith(isRefreshing: true, clearRefreshFailure: true);
    } else {
      state = state.copyWith(
        status: HomeStatus.loading,
        isRefreshing: false,
        clearPrimaryFailure: true,
        clearRefreshFailure: true,
      );
    }

    if (!refresh && state.featuredCourses.isEmpty) {
      try {
        final cachedResult = await _repository.loadHomeFromCache();
        if (cachedResult != null && mounted && state.status == HomeStatus.loading) {
          state = HomeState(
            status: HomeStatus.success,
            featuredCourses: cachedResult.featuredCourses,
            continueLearning: cachedResult.continueLearning,
            categories: cachedResult.categories,
            articles: cachedResult.articles,
            testimonials: cachedResult.testimonials,
          );
        }
      } catch (_) {}
    }

    try {
      final result = await _repository.loadHome();
      if (!mounted) {
        return;
      }

      state = HomeState(
        status: HomeStatus.success,
        featuredCourses: result.featuredCourses,
        continueLearning: result.continueLearning,
        categories: result.categories,
        articles: result.articles,
        testimonials: result.testimonials,
        enrollmentIssue: result.enrollmentIssue,
        categoryIssue: result.categoryIssue,
        articleIssue: result.articleIssue,
        testimonialIssue: result.testimonialIssue,
      );
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }

      if (refresh && state.hasLoadedContent) {
        state = state.copyWith(
          status: HomeStatus.success,
          isRefreshing: false,
          refreshFailure: failure,
          clearPrimaryFailure: true,
        );
        return;
      }

      state = state.copyWith(
        status: HomeStatus.failure,
        primaryFailure: failure,
        isRefreshing: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final failure = AppFailure(
        type: AppFailureType.unknown,
        message: 'Something went wrong. Please try again.',
        originalCause: error,
      );

      if (refresh && state.hasLoadedContent) {
        state = state.copyWith(
          status: HomeStatus.success,
          isRefreshing: false,
          refreshFailure: failure,
          clearPrimaryFailure: true,
        );
        return;
      }

      state = state.copyWith(
        status: HomeStatus.failure,
        primaryFailure: failure,
        isRefreshing: false,
      );
    }
  }

  Future<void> refresh() => load(refresh: true);
}
