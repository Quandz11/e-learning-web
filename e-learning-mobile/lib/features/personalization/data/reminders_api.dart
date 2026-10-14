import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/personalization/domain/reminder_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remindersApiProvider = Provider<RemindersApi>((ref) {
  return RemindersApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
  );
});

class RemindersApi {
  RemindersApi({
    required ApiClient apiClient,
    required DioErrorMapper errorMapper,
  }) : _apiClient = apiClient,
       _errorMapper = errorMapper;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;

  Future<List<Reminder>> getReminders() async {
    try {
      final data = await _apiClient.get<Object?>('/user/reminders');
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) =>
                  Reminder.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
            )
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }

  Future<List<Reminder>> syncReminders(List<Reminder> reminders) async {
    try {
      final payload = {'reminders': reminders.map((r) => r.toJson()).toList()};
      final data = await _apiClient.post<Object?>(
        '/user/reminders/sync',
        data: payload,
      );
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) =>
                  Reminder.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
            )
            .toList();
      }
      return reminders;
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }

  Future<Reminder?> upsertReminder(Reminder reminder) async {
    try {
      final data = await _apiClient.post<Object?>(
        '/user/reminders',
        data: reminder.toJson(),
      );
      if (data is Map) {
        return Reminder.fromJson(data.map((k, v) => MapEntry(k.toString(), v)));
      }
      return reminder;
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _apiClient.delete<Object?>('/user/reminders/$id');
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    try {
      await _apiClient.patch<Object?>(
        '/user/reminders/$id/toggle',
        data: enabled,
      );
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppFailure) throw mapped;
      throw _errorMapper.map(e);
    }
  }
}
