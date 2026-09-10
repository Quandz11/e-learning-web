import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/home/data/home_api.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(api: ref.read(homeApiProvider));
});

class HomeRepository {
  const HomeRepository({required HomeApi api}) : _api = api;

  final HomeApi _api;

  Future<HomeLoadResult?> loadHomeFromCache() async {
    try {
      final featuredCourses = await _api.getCachedPublishedCourses();
      if (featuredCourses == null) return null;

      final enrollments = await _api.getCachedEnrollments() ?? const [];
      final categories = await _api.getCachedActiveCategories() ?? const [];
      final articles = await _api.getCachedRecentArticles() ?? const [];
      final testimonials = await _api.getCachedActiveTestimonials() ?? const [];

      return HomeLoadResult(
        featuredCourses: featuredCourses
            .where((course) => course.isPublished)
            .take(4)
            .toList(growable: false),
        continueLearning: _selectContinueLearning(enrollments),
        categories: categories
            .where((category) => category.isActive)
            .toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order)),
        articles: articles.take(4).toList(growable: false),
        testimonials: testimonials.take(2).toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<HomeLoadResult> loadHome() async {
    try {
      final feed = await _api.getMobileHomeFeed();
      return HomeLoadResult(
        featuredCourses: feed.courses
            .where((course) => course.isPublished)
            .take(4)
            .toList(growable: false),
        continueLearning: _selectContinueLearning(feed.enrollments),
        categories: feed.categories
            .where((category) => category.isActive)
            .toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order)),
        articles: feed.articles.take(4).toList(growable: false),
        testimonials: feed.testimonials.take(2).toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order)),
      );
    } catch (_) {
      // Graceful fallback to individual endpoints
      final featuredCoursesFuture = _api.getPublishedCourses();
      final enrollmentsFuture = _captureOptional(_api.getEnrollments);
      final categoriesFuture = _captureOptional(_api.getActiveCategories);
      final articlesFuture = _captureOptional(
        () => _api.getRecentArticles(pageSize: 4),
      );
      final testimonialsFuture = _captureOptional(_api.getActiveTestimonials);

      final featuredCourses = await featuredCoursesFuture;
      final enrollments = await enrollmentsFuture;
      final categories = await categoriesFuture;
      final articles = await articlesFuture;
      final testimonials = await testimonialsFuture;

      return HomeLoadResult(
        featuredCourses: featuredCourses
            .where((course) => course.isPublished)
            .take(4)
            .toList(growable: false),
        continueLearning: _selectContinueLearning(enrollments.data),
        categories:
            categories.data
                .where((category) => category.isActive)
                .toList(growable: false)
              ..sort((left, right) => left.order.compareTo(right.order)),
        articles: articles.data.take(4).toList(growable: false),
        testimonials: testimonials.data.take(2).toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order)),
        enrollmentIssue: enrollments.failure == null
            ? null
            : HomeSectionIssue(failure: enrollments.failure!),
        categoryIssue: categories.failure == null
            ? null
            : HomeSectionIssue(failure: categories.failure!),
        articleIssue: articles.failure == null
            ? null
            : HomeSectionIssue(failure: articles.failure!),
        testimonialIssue: testimonials.failure == null
            ? null
            : HomeSectionIssue(failure: testimonials.failure!),
      );
    }
  }

  HomeEnrollment? _selectContinueLearning(List<HomeEnrollment> enrollments) {
    final candidates = enrollments
        .where((enrollment) => !enrollment.isExpired && !enrollment.isCompleted)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (left, right) => right.lastAccessedAt.compareTo(left.lastAccessedAt),
    );
    return candidates.first;
  }

  Future<_OptionalResult<T>> _captureOptional<T>(
    Future<List<T>> Function() action,
  ) async {
    try {
      return _OptionalResult<T>(data: await action());
    } on AppFailure catch (failure) {
      return _OptionalResult<T>(data: const [], failure: failure);
    } catch (error) {
      return _OptionalResult<T>(
        data: const [],
        failure: AppFailure(
          type: AppFailureType.unknown,
          message: 'Something went wrong. Please try again.',
          originalCause: error,
        ),
      );
    }
  }
}

class _OptionalResult<T> {
  const _OptionalResult({required this.data, this.failure});

  final List<T> data;
  final AppFailure? failure;
}
