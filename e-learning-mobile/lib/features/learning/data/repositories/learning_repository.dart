import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../models/course_models.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.read(apiClientProvider));
});

class LearningRepository {
  LearningRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CourseSummaryModel>> getCourses() async {
    final data = await _apiClient.get<List<dynamic>>('/courses');
    return data
        .whereType<Map<String, dynamic>>()
        .map(CourseSummaryModel.fromJson)
        .toList();
  }

  Future<CourseDetailModel> getCourseDetail(String courseId) async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      '/courses/$courseId',
    );
    return CourseDetailModel.fromJson(data);
  }

  Future<void> enroll(String courseId) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/enrollments',
      data: {'courseId': courseId},
    );
  }

  Future<List<Map<String, dynamic>>> getMyCourses() async {
    final data = await _apiClient.get<List<dynamic>>('/enrollments');
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<EnrollmentProgressModel> getProgress(String courseId) async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      '/enrollments/$courseId/progress',
    );
    return EnrollmentProgressModel.fromJson(data);
  }

  Future<void> updateLessonProgress({
    required String courseId,
    required String lessonPartId,
    required int watchedDuration,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/enrollments/$courseId/lessons/$lessonPartId/progress',
      data: {'watchedDuration': watchedDuration},
    );
  }

  Future<void> markLessonComplete({
    required String courseId,
    required String lessonPartId,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/enrollments/$courseId/lessons/$lessonPartId/complete',
    );
  }
}
