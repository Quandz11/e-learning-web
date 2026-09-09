import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/learning/data/models/learning_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final learningApiProvider = Provider<LearningApi>((ref) {
  final config = ref.read(appConfigProvider);
  return LearningApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
    apiBaseUrl: config.apiBaseUrl,
  );
});

class LearningApi {
  LearningApi({
    required ApiClient apiClient,
    required DioErrorMapper errorMapper,
    required Uri apiBaseUrl,
  }) : _apiClient = apiClient,
       _errorMapper = errorMapper,
       _apiBaseUrl = apiBaseUrl;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;
  final Uri _apiBaseUrl;

  Future<List<LearningCourse>> getPublishedCourses() async {
    final rows = await _getJsonList(
      '/courses',
      queryParameters: const {'isPublished': true},
    );

    return rows.map(_parseCourse).toList(growable: false);
  }

  Future<List<LearningEnrollment>> getEnrollments() async {
    final rows = await _getJsonList('/enrollments');
    return rows.map(_parseEnrollment).toList(growable: false);
  }

  Future<List<LearningCategory>> getActiveCategories() async {
    final rows = await _getJsonList('/categories/active');
    return rows.map(_parseCategory).toList(growable: false);
  }

  Future<LearningCourse> getCourse(String courseId) async {
    try {
      final data = await _apiClient.get<Object?>('/courses/$courseId');
      return _parseCourse(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<LearningCourseProgress> getCourseProgress(String courseId) async {
    try {
      final data = await _apiClient.get<Object?>(
        '/enrollments/$courseId/progress',
      );
      return _parseCourseProgress(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<void> markLessonComplete({
    required String courseId,
    required String lessonPartId,
  }) async {
    try {
      await _apiClient.post<Object?>(
        '/enrollments/$courseId/lessons/$lessonPartId/complete',
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<Map<String, dynamic>>> _getJsonList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final data = await _apiClient.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return _coerceJsonList(data);
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

  List<Map<String, dynamic>> _coerceJsonList(Object? data) {
    if (data is! List) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid response.',
      );
    }

    return data.map(_coerceJsonMap).toList(growable: false);
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

  LearningCourse _parseCourse(Map<String, dynamic> json) {
    final lecturer = json['lecturer'];
    final learningOutcomes = json['learningOutcomes'];

    return LearningCourse(
      id: _requireString(json['id']),
      title: _requireString(json['title']).trim(),
      description: _optionalString(json['description']),
      price: _requireNum(json['price']),
      isFree: _requireBool(json['isFree']),
      isPublished: _requireBool(json['isPublished']),
      instructorName: lecturer is Map
          ? _optionalString(lecturer['fullName'])
          : null,
      thumbnailUrl: _resolveUrl(_optionalString(json['thumbnailUrl'])),
      defaultAccessDurationDays: _optionalInt(
        json['defaultAccessDurationDays'],
      ),
      learningOutcomes: learningOutcomes is List
          ? learningOutcomes
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const [],
      createdAt: _requireDateTime(json['createdAt']),
      lessons: _parseLessons(json['lessons']),
    );
  }

  LearningEnrollment _parseEnrollment(Map<String, dynamic> json) {
    return LearningEnrollment(
      id: _requireString(json['id']),
      courseId: _requireString(json['courseId']),
      courseTitle: _requireString(json['courseTitle']).trim(),
      courseThumbnail: _resolveUrl(_optionalString(json['courseThumbnail'])),
      enrolledAt: _requireDateTime(json['enrolledAt']),
      progressPercentage: _requireInt(
        json['progressPercentage'],
      ).clamp(0, 100).toInt(),
      completedAt: _optionalDateTime(json['completedAt']),
      lastAccessedAt: _requireDateTime(json['lastAccessedAt']),
      accessDurationDays: _optionalInt(json['accessDurationDays']),
      accessExpiresAt: _optionalDateTime(json['accessExpiresAt']),
      isExpired: _requireBool(json['isExpired']),
      status: _requireString(json['status']).trim(),
    );
  }

  LearningCategory _parseCategory(Map<String, dynamic> json) {
    return LearningCategory(
      id: _requireString(json['id']),
      name: _requireString(json['name']).trim(),
      description: _optionalString(json['description']),
      order: _requireInt(json['order']),
      isActive: _requireBool(json['isActive']),
      createdAt: _requireDateTime(json['createdAt']),
    );
  }

  LearningCourseProgress _parseCourseProgress(Map<String, dynamic> json) {
    final partProgress = json['partProgress'];
    return LearningCourseProgress(
      enrollmentId: _requireString(json['enrollmentId']),
      progressPercentage: _requireInt(
        json['progressPercentage'],
      ).clamp(0, 100).toInt(),
      completedParts: _requireInt(json['completedParts']),
      totalParts: _requireInt(json['totalParts']),
      completedAt: _optionalDateTime(json['completedAt']),
      accessDurationDays: _optionalInt(json['accessDurationDays']),
      accessExpiresAt: _optionalDateTime(json['accessExpiresAt']),
      isExpired: _requireBool(json['isExpired']),
      partProgress: partProgress is List
          ? partProgress
                .map(_coerceJsonMap)
                .map(_parseLessonProgress)
                .toList(growable: false)
          : const [],
    );
  }

  LearningLessonProgress _parseLessonProgress(Map<String, dynamic> json) {
    return LearningLessonProgress(
      lessonPartId: _requireString(json['lessonPartId']),
      lessonPartTitle: _requireString(json['lessonPartTitle']).trim(),
      isCompleted: _requireBool(json['isCompleted']),
      watchedDuration: _requireInt(json['watchedDuration']),
      completedAt: _optionalDateTime(json['completedAt']),
      lastWatchedAt: _requireDateTime(json['lastWatchedAt']),
    );
  }

  List<LearningLesson> _parseLessons(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.map(_coerceJsonMap).map(_parseLesson).toList(growable: false);
  }

  LearningLesson _parseLesson(Map<String, dynamic> json) {
    final parts = json['parts'];
    return LearningLesson(
      id: _requireString(json['id']),
      title: _requireString(json['title']).trim(),
      description: _optionalString(json['description']),
      thumbnailUrl: _resolveUrl(_optionalString(json['thumbnailUrl'])),
      categoryName: _optionalString(json['categoryName']),
      createdAt: _requireDateTime(json['createdAt']),
      updatedAt: _optionalDateTime(json['updatedAt']),
      parts: parts is List
          ? parts.map(_coerceJsonMap).map(_parsePart).toList(growable: false)
          : const [],
    );
  }

  LearningLessonPart _parsePart(Map<String, dynamic> json) {
    return LearningLessonPart(
      id: _requireString(json['id']),
      title: _requireString(json['title']).trim(),
      type: _requireString(json['type']).trim(),
      orderIndex: _requireInt(json['orderIndex']),
      isPreview: _requireBool(json['isPreview']),
      videoId: _optionalString(json['videoId']),
      videoDuration: _requireDouble(json['videoDuration']),
      playbackUrl: _resolveUrl(_optionalString(json['playbackUrl'])),
      embedUrl: _resolveUrl(_optionalString(json['embedUrl'])),
      documentId: _optionalString(json['documentId']),
      documentUrl: _resolveUrl(_optionalString(json['documentUrl'])),
      documentFileName: _optionalString(json['documentFileName']),
      content: _optionalString(json['content']),
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

  double _requireDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
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

    if (raw.startsWith('//')) {
      return Uri.parse('https:$raw').toString();
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
