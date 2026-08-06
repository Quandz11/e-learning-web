import 'package:e_learning_mobile/core/errors/app_failure.dart';

class HomeCourse {
  const HomeCourse({
    required this.id,
    required this.title,
    required this.price,
    required this.isFree,
    required this.isPublished,
    required this.createdAt,
    this.instructorName,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final num price;
  final bool isFree;
  final bool isPublished;
  final DateTime createdAt;
  final String? instructorName;
  final String? thumbnailUrl;
}

class HomeEnrollment {
  const HomeEnrollment({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.enrolledAt,
    required this.progressPercentage,
    required this.lastAccessedAt,
    required this.isExpired,
    required this.status,
    this.courseThumbnail,
    this.completedAt,
    this.accessDurationDays,
    this.accessExpiresAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String? courseThumbnail;
  final DateTime enrolledAt;
  final int progressPercentage;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;
  final int? accessDurationDays;
  final DateTime? accessExpiresAt;
  final bool isExpired;
  final String status;

  bool get isCompleted => progressPercentage >= 100 || completedAt != null;
}

class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    required this.order,
    required this.isActive,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final int order;
  final bool isActive;
}

class HomeArticle {
  const HomeArticle({
    required this.id,
    required this.title,
    required this.slug,
    required this.isPublished,
    required this.createdAt,
    this.excerpt,
    this.featuredImageUrl,
    this.categoryName,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? featuredImageUrl;
  final String? categoryName;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
}

class HomeTestimonial {
  const HomeTestimonial({
    required this.id,
    required this.name,
    required this.content,
    required this.order,
    this.position,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String content;
  final int order;
  final String? position;
  final String? avatarUrl;
}

class HomeSectionIssue {
  const HomeSectionIssue({required this.failure});

  final AppFailure failure;
}

class HomeLoadResult {
  const HomeLoadResult({
    required this.featuredCourses,
    required this.continueLearning,
    required this.categories,
    required this.articles,
    required this.testimonials,
    this.enrollmentIssue,
    this.categoryIssue,
    this.articleIssue,
    this.testimonialIssue,
  });

  final List<HomeCourse> featuredCourses;
  final HomeEnrollment? continueLearning;
  final List<HomeCategory> categories;
  final List<HomeArticle> articles;
  final List<HomeTestimonial> testimonials;
  final HomeSectionIssue? enrollmentIssue;
  final HomeSectionIssue? categoryIssue;
  final HomeSectionIssue? articleIssue;
  final HomeSectionIssue? testimonialIssue;
}
