import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final runningApiProvider = Provider<RunningApi>((ref) {
  return RunningApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
  );
});

class RunningApi {
  RunningApi({
    required ApiClient apiClient,
    required DioErrorMapper errorMapper,
  }) : _apiClient = apiClient,
       _errorMapper = errorMapper;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;

  Future<RunningSummary> getSummary() async {
    try {
      final data = await _apiClient.get<Object?>('/running/summary');
      if (data is Map) {
        return RunningSummary.fromJson(
          data.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      return const RunningSummary();
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }

  Future<({List<RunningActivity> items, int totalCount})> getActivities({
    int page = 1,
    int pageSize = 20,
    int? month,
    int? year,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };

      final data = await _apiClient.get<Object?>(
        '/running/activities',
        queryParameters: queryParams,
      );

      if (data is Map) {
        final map = data.map((k, v) => MapEntry(k.toString(), v));
        final rawItems = map['items'];
        final total = (map['totalCount'] as num?)?.toInt() ?? 0;
        final list = <RunningActivity>[];
        if (rawItems is List) {
          for (final item in rawItems) {
            if (item is Map) {
              list.add(
                RunningActivity.fromJson(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ),
              );
            }
          }
        }
        return (items: list, totalCount: total);
      }
      return (items: const <RunningActivity>[], totalCount: 0);
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }

  Future<RunningActivity> createActivity(CreateRunningActivityDto dto) async {
    try {
      final data = await _apiClient.post<Object?>(
        '/running/activities',
        data: dto.toJson(),
      );
      if (data is Map) {
        return RunningActivity.fromJson(
          data.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      throw const AppFailure(
        type: AppFailureType.unknown,
        message: 'Dữ liệu phản hồi không hợp lệ.',
      );
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }

  Future<bool> deleteActivity(String id) async {
    try {
      await _apiClient.delete<Object?>('/running/activities/$id');
      return true;
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }
}
