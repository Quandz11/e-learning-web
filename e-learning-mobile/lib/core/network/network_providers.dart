import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_loader.dart';
import '../telemetry/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final env = ref.read(appEnvProvider);
  final logger = ref.read(appLoggerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    ErrorInterceptor(),
    LoggingInterceptor(logger),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<T>(path, queryParameters: queryParameters);
    return response.data as T;
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as T;
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data as T;
  }

  Future<T> patch<T>(String path, {Object? data}) async {
    final response = await _dio.patch<T>(path, data: data);
    return response.data as T;
  }

  Future<T> delete<T>(String path, {Object? data}) async {
    final response = await _dio.delete<T>(path, data: data);
    return response.data as T;
  }
}
