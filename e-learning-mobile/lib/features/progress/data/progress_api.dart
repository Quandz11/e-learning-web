import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/progress/data/models/progress_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final progressApiProvider = Provider<ProgressApi>((ref) {
  return ProgressApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
  );
});

class ProgressApi {
  ProgressApi({
    required ApiClient apiClient,
    required DioErrorMapper errorMapper,
  }) : _apiClient = apiClient,
       _errorMapper = errorMapper;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;

  Future<LearningProgressSummary> getProgressSummary() async {
    try {
      final data = await _apiClient.get<Object?>(
        '/mobile/learning/progress-summary',
      );
      if (data is Map<String, dynamic>) {
        return LearningProgressSummary.fromJson(data);
      }
      if (data is Map) {
        return LearningProgressSummary.fromJson(
          data.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'Invalid progress summary response',
      );
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }
}
