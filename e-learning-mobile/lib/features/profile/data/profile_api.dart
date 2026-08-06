import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/features/auth/data/models/message_response.dart';
import 'package:e_learning_mobile/features/profile/data/models/change_password_request.dart';
import 'package:e_learning_mobile/features/profile/data/models/profile.dart';
import 'package:e_learning_mobile/features/profile/data/models/update_profile_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(
    apiClient: ref.read(apiClientProvider),
    errorMapper: ref.read(dioErrorMapperProvider),
  );
});

class ProfileApi {
  ProfileApi({
    required ApiClient apiClient,
    required DioErrorMapper errorMapper,
  }) : _apiClient = apiClient,
       _errorMapper = errorMapper;

  final ApiClient _apiClient;
  final DioErrorMapper _errorMapper;

  Future<Profile> getProfile() async {
    final data = await _getJson('/profile/me');
    try {
      return Profile.fromJson(data);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw _malformedProfileFailure(error);
    }
  }

  Future<Profile> updateProfile(UpdateProfileRequest request) async {
    final data = await _putJson('/profile/me', request.toJson());
    try {
      return Profile.fromJson(data);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw _malformedProfileFailure(error);
    }
  }

  Future<String> changePassword(ChangePasswordRequest request) async {
    final data = await _postJson('/profile/change-password', request.toJson());
    try {
      return MessageResponse.fromJson(data).message;
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid response.',
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    try {
      final data = await _apiClient.get<Object?>(path);
      return _coerceJson(data);
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final data = await _apiClient.post<Object?>(path, data: body);
      return _coerceJson(data);
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> _putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final data = await _apiClient.put<Object?>(path, data: body);
      return _coerceJson(data);
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Map<String, dynamic> _coerceJson(Object? data) {
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

  AppFailure _map(DioException error) {
    final mapped = error.error;
    if (mapped is AppFailure) {
      return mapped;
    }
    return _errorMapper.map(error);
  }

  AppFailure _malformedProfileFailure(Object? cause) {
    return AppFailure(
      type: AppFailureType.malformedResponse,
      message: 'The server returned an invalid profile response.',
      debugDetails: cause?.toString(),
      originalCause: cause,
    );
  }
}
