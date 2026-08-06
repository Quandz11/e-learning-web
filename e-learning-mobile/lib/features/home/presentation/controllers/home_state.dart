import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  const HomeState({
    this.status = HomeStatus.initial,
    this.featuredCourses = const [],
    this.categories = const [],
    this.articles = const [],
    this.testimonials = const [],
    this.continueLearning,
    this.primaryFailure,
    this.refreshFailure,
    this.enrollmentIssue,
    this.categoryIssue,
    this.articleIssue,
    this.testimonialIssue,
    this.isRefreshing = false,
  });

  final HomeStatus status;
  final List<HomeCourse> featuredCourses;
  final List<HomeCategory> categories;
  final List<HomeArticle> articles;
  final List<HomeTestimonial> testimonials;
  final HomeEnrollment? continueLearning;
  final AppFailure? primaryFailure;
  final AppFailure? refreshFailure;
  final HomeSectionIssue? enrollmentIssue;
  final HomeSectionIssue? categoryIssue;
  final HomeSectionIssue? articleIssue;
  final HomeSectionIssue? testimonialIssue;
  final bool isRefreshing;

  bool get hasLoadedContent =>
      featuredCourses.isNotEmpty ||
      continueLearning != null ||
      categories.isNotEmpty ||
      articles.isNotEmpty ||
      testimonials.isNotEmpty;

  bool get isInitialLoading =>
      status == HomeStatus.loading && !hasLoadedContent && !isRefreshing;

  HomeState copyWith({
    HomeStatus? status,
    List<HomeCourse>? featuredCourses,
    List<HomeCategory>? categories,
    List<HomeArticle>? articles,
    List<HomeTestimonial>? testimonials,
    HomeEnrollment? continueLearning,
    bool clearContinueLearning = false,
    AppFailure? primaryFailure,
    bool clearPrimaryFailure = false,
    AppFailure? refreshFailure,
    bool clearRefreshFailure = false,
    HomeSectionIssue? enrollmentIssue,
    bool clearEnrollmentIssue = false,
    HomeSectionIssue? categoryIssue,
    bool clearCategoryIssue = false,
    HomeSectionIssue? articleIssue,
    bool clearArticleIssue = false,
    HomeSectionIssue? testimonialIssue,
    bool clearTestimonialIssue = false,
    bool? isRefreshing,
  }) {
    return HomeState(
      status: status ?? this.status,
      featuredCourses: featuredCourses ?? this.featuredCourses,
      categories: categories ?? this.categories,
      articles: articles ?? this.articles,
      testimonials: testimonials ?? this.testimonials,
      continueLearning: clearContinueLearning
          ? null
          : continueLearning ?? this.continueLearning,
      primaryFailure: clearPrimaryFailure
          ? null
          : primaryFailure ?? this.primaryFailure,
      refreshFailure: clearRefreshFailure
          ? null
          : refreshFailure ?? this.refreshFailure,
      enrollmentIssue: clearEnrollmentIssue
          ? null
          : enrollmentIssue ?? this.enrollmentIssue,
      categoryIssue: clearCategoryIssue
          ? null
          : categoryIssue ?? this.categoryIssue,
      articleIssue: clearArticleIssue
          ? null
          : articleIssue ?? this.articleIssue,
      testimonialIssue: clearTestimonialIssue
          ? null
          : testimonialIssue ?? this.testimonialIssue,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
