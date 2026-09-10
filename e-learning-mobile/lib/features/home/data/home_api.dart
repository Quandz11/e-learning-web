import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/home/data/models/home_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_learning_mobile/core/network/cache_service.dart';

final homeApiProvider = Provider<HomeApi>((ref) {
  final config = ref.read(appConfigProvider);
  return HomeApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
    apiBaseUrl: config.apiBaseUrl,
    cacheService: ref.read(cacheServiceProvider),
  );
});

class HomeApi {
  HomeApi({
    required ApiClient apiClient,
    required DioErrorMapper errorMapper,
    required Uri apiBaseUrl,
    CacheService? cacheService,
  })  : _apiClient = apiClient,
        _errorMapper = errorMapper,
        _apiBaseUrl = apiBaseUrl,
        _cacheService = cacheService;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;
  final Uri _apiBaseUrl;
  final CacheService? _cacheService;

  Future<HomeFeedData> getMobileHomeFeed() async {
    final data = await _getJsonMap('/mobile/home-feed');
    final courses = _coerceJsonList(data['featuredCourses']).map(_parseCourse).toList(growable: false);
    final enrollments = _coerceJsonList(data['myEnrollments']).map(_parseEnrollment).toList(growable: false);
    final categories = _coerceJsonList(data['categories']).map(_parseCategory).toList(growable: false);
    final articles = _coerceJsonList(data['recentArticles']).map(_parseArticle).toList(growable: false);
    final testimonials = _coerceJsonList(data['testimonials']).map(_parseTestimonial).toList(growable: false);

    return HomeFeedData(
      courses: courses,
      enrollments: enrollments,
      categories: categories,
      articles: articles,
      testimonials: testimonials,
    );
  }

  Future<List<HomeCourse>> getPublishedCourses() async {
    final rows = await _getJsonList(
      '/courses',
      queryParameters: const {'isPublished': true},
    );

    return rows.map(_parseCourse).toList(growable: false);
  }

  Future<List<HomeEnrollment>> getEnrollments() async {
    final rows = await _getJsonList('/enrollments');
    return rows.map(_parseEnrollment).toList(growable: false);
  }

  Future<List<HomeCategory>> getActiveCategories() async {
    final rows = await _getJsonList('/categories/active');
    return rows.map(_parseCategory).toList(growable: false);
  }

  Future<List<HomeArticle>> getRecentArticles({int pageSize = 4}) async {
    final data = await _getJsonMap(
      '/articles',
      queryParameters: {'page': 1, 'pageSize': pageSize},
    );
    final items = _coerceJsonList(data['items']);
    return items.map(_parseArticle).toList(growable: false);
  }

  Future<List<HomeTestimonial>> getActiveTestimonials() async {
    final rows = await _getJsonList('/testimonials/active');
    return rows.map(_parseTestimonial).toList(growable: false);
  }

  Future<List<HomeCourse>?> getCachedPublishedCourses() async {
    final cached = await _cacheService?.getList('/courses?isPublished=true');
    if (cached == null) return null;
    try {
      final rows = _coerceJsonList(cached);
      return rows.map(_parseCourse).toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<List<HomeEnrollment>?> getCachedEnrollments() async {
    final cached = await _cacheService?.getList('/enrollments');
    if (cached == null) return null;
    try {
      final rows = _coerceJsonList(cached);
      return rows.map(_parseEnrollment).toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<List<HomeCategory>?> getCachedActiveCategories() async {
    final cached = await _cacheService?.getList('/categories/active');
    if (cached == null) return null;
    try {
      final rows = _coerceJsonList(cached);
      return rows.map(_parseCategory).toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<List<HomeArticle>?> getCachedRecentArticles() async {
    final cached = await _cacheService?.getMap('/articles?page=1&pageSize=4');
    if (cached == null) return null;
    try {
      final items = _coerceJsonList(cached['items']);
      return items.map(_parseArticle).toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<List<HomeTestimonial>?> getCachedActiveTestimonials() async {
    final cached = await _cacheService?.getList('/testimonials/active');
    if (cached == null) return null;
    try {
      final rows = _coerceJsonList(cached);
      return rows.map(_parseTestimonial).toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJsonMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final cacheKey = queryParameters != null && queryParameters.isNotEmpty
        ? '$path?${Uri(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString()))).query}'
        : path;
    try {
      final data = await _apiClient.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      final map = _coerceJsonMap(data);
      _cacheService?.set(cacheKey, map);
      return map;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<Map<String, dynamic>>> _getJsonList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final cacheKey = queryParameters != null && queryParameters.isNotEmpty
        ? '$path?${Uri(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString()))).query}'
        : path;
    try {
      final data = await _apiClient.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      final list = _coerceJsonList(data);
      _cacheService?.set(cacheKey, list);
      return list;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  AppFailure _map(DioException error) {
    final mapped = error.error;
    if (mapped is AppFailure) {
      return mapped;
    }
    return _errorMapper.map(error);
  }

  Map<String, dynamic> _coerceJsonMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  List<Map<String, dynamic>> _coerceJsonList(Object? data) {
    if (data is! List) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid response.',
      );
    }

    return data.map((item) => _coerceJsonMap(item)).toList(growable: false);
  }

  HomeCourse _parseCourse(Map<String, dynamic> json) {
    final id = _requireString(json['id']);
    final title = _requireString(json['title']);
    final price = _requireNum(json['price']);
    final isFree = _requireBool(json['isFree']);
    final isPublished = _requireBool(json['isPublished']);
    final createdAt = _requireDateTime(json['createdAt']);
    final lecturer = json['lecturer'];

    return HomeCourse(
      id: id,
      title: title.trim(),
      price: price,
      isFree: isFree,
      isPublished: isPublished,
      createdAt: createdAt,
      instructorName: lecturer is Map
          ? _optionalString(lecturer['fullName'])
          : null,
      thumbnailUrl: _resolveUrl(_optionalString(json['thumbnailUrl'])),
    );
  }

  HomeEnrollment _parseEnrollment(Map<String, dynamic> json) {
    return HomeEnrollment(
      id: _requireString(json['id']),
      courseId: _requireString(json['courseId']),
      courseTitle: _requireString(json['courseTitle']).trim(),
      courseThumbnail: _resolveUrl(_optionalString(json['courseThumbnail'])),
      enrolledAt: _requireDateTime(json['enrolledAt']),
      progressPercentage: _requireInt(json['progressPercentage']),
      completedAt: _optionalDateTime(json['completedAt']),
      lastAccessedAt: _requireDateTime(json['lastAccessedAt']),
      accessDurationDays: _optionalInt(json['accessDurationDays']),
      accessExpiresAt: _optionalDateTime(json['accessExpiresAt']),
      isExpired: _requireBool(json['isExpired']),
      status: _requireString(json['status']).trim(),
    );
  }

  HomeCategory _parseCategory(Map<String, dynamic> json) {
    return HomeCategory(
      id: _requireString(json['id']),
      name: _requireString(json['name']).trim(),
      description: _optionalString(json['description']),
      order: _requireInt(json['order']),
      isActive: _requireBool(json['isActive']),
    );
  }

  HomeArticle _parseArticle(Map<String, dynamic> json) {
    return HomeArticle(
      id: _requireString(json['id']),
      title: _requireString(json['title']).trim(),
      slug: _requireString(json['slug']).trim(),
      excerpt: _optionalString(json['excerpt']),
      featuredImageUrl: _resolveUrl(_optionalString(json['featuredImageUrl'])),
      categoryName: _optionalString(json['categoryName']),
      isPublished: _requireBool(json['isPublished']),
      publishedAt: _optionalDateTime(json['publishedAt']),
      createdAt: _requireDateTime(json['createdAt']),
    );
  }

  HomeTestimonial _parseTestimonial(Map<String, dynamic> json) {
    return HomeTestimonial(
      id: _requireString(json['id']),
      name: _requireString(json['name']).trim(),
      content: _requireString(json['content']).trim(),
      order: _requireInt(json['order']),
      position: _optionalString(json['position']),
      avatarUrl: _resolveUrl(_optionalString(json['avatarUrl'])),
    );
  }

  String _requireString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  String? _optionalString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _requireBool(Object? value) {
    if (value is bool) {
      return value;
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  num _requireNum(Object? value) {
    if (value is num) {
      return value;
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  int _requireInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  int? _optionalInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  DateTime _requireDateTime(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value)?.toUtc();
      if (parsed != null) {
        return parsed;
      }
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  DateTime? _optionalDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value)?.toUtc();
      if (parsed != null) {
        return parsed;
      }
    }
    throw const AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid response.',
    );
  }

  String? _resolveUrl(String? raw) {
    if (raw == null) {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      return null;
    }
    if (uri.hasScheme) {
      return uri.toString();
    }

    return _apiBaseUrl.resolveUri(uri).toString();
  }
}
