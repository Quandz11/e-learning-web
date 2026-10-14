import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/personalization/data/models/wellness_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wellnessApiProvider = Provider<WellnessApi>((ref) {
  return WellnessApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
  );
});

class WellnessApi {
  WellnessApi({
    required ApiClient apiClient,
    required DioErrorMapper errorMapper,
  }) : _apiClient = apiClient,
       _errorMapper = errorMapper;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;

  Future<WellnessDashboard> getDashboard() async {
    try {
      final data = await _apiClient.get<Object?>('/wellness/dashboard');
      return WellnessDashboard.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessPlan> upsertPlan(UpsertWellnessPlanRequest request) async {
    try {
      final data = await _apiClient.post<Object?>(
        '/wellness/plan',
        data: request.toJson(),
      );
      return WellnessPlan.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessPlan> updateSchedule(
    String planId,
    UpdateWellnessScheduleRequest request,
  ) async {
    try {
      final data = await _apiClient.put<Object?>(
        '/wellness/plan/$planId/schedule',
        data: request.toJson(),
      );
      return WellnessPlan.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessDailyLog> upsertDailyLog(
    String planId,
    UpsertWellnessDailyLogRequest request,
  ) async {
    try {
      final data = await _apiClient.put<Object?>(
        '/wellness/plan/$planId/daily-log',
        data: request.toJson(),
      );
      return WellnessDailyLog.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessCoachReply> askMoodCoach(
    String planId,
    WellnessCoachMoodRequest request,
  ) async {
    try {
      final data = await _apiClient.post<Object?>(
        '/wellness/plan/$planId/coach/mood',
        data: request.toJson(),
      );
      return WellnessCoachReply.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessMealSuggestion> generateMeal(
    String planId,
    WellnessCoachMealRequest request,
  ) async {
    try {
      final data = await _apiClient.post<Object?>(
        '/wellness/plan/$planId/coach/meal',
        data: request.toJson(),
      );
      return WellnessMealSuggestion.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessDailyTask> completeTask(String planId, String taskId) async {
    try {
      final data = await _apiClient.put<Object?>(
        '/wellness/plan/$planId/tasks/$taskId/complete',
      );
      return WellnessDailyTask.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessWeightProgress> getWeightProgress(String planId) async {
    try {
      final data = await _apiClient.get<Object?>(
        '/wellness/plan/$planId/weight-progress',
      );
      return WellnessWeightProgress.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessProgressTimeline> getProgressTimeline(
    String planId, {
    int days = 30,
    bool includeFuture = false,
  }) async {
    try {
      final data = await _apiClient.get<Object?>(
        '/wellness/plan/$planId/progress-timeline',
        queryParameters: {'days': days, 'includeFuture': includeFuture},
      );
      return WellnessProgressTimeline.fromJson(_coerceJsonMap(data));
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<WellnessResourceItem>> getResources() async {
    try {
      final data = await _apiClient.get<Object?>('/wellness/resources');
      if (data is! List) return [];
      return data
          .map(_coerceJsonMap)
          .map(WellnessResourceItem.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<WellnessCheckoutConfig> getCheckoutConfig() async {
    try {
      final data = await _apiClient.get<Object?>('/wellness/checkout-config');
      return WellnessCheckoutConfig.fromJson(_coerceJsonMap(data));
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
}
