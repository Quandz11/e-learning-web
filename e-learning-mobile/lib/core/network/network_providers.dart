import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:e_learning_mobile/core/network/api_client.dart';
import 'package:e_learning_mobile/core/network/auth_interceptor.dart';
import 'package:e_learning_mobile/core/network/dev_network_support.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioErrorMapperProvider = Provider<DioErrorMapper>((_) {
  return const DioErrorMapper();
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.read(appConfigProvider);
  final mapper = ref.read(dioErrorMapperProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl.toString(),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  configureDevelopmentTransport(dio, config);

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      sessionRepository: ref.read(sessionRepositoryProvider),
      sessionController: ref.read(sessionControllerProvider.notifier),
    ),
  );
  if (shouldEnableDevelopmentHttpDiagnostics(config)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logRequestStart(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          logResponseResult(
            options: response.requestOptions,
            statusCode: response.statusCode,
          );
          handler.next(response);
        },
      ),
    );
  }
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        final mappedFailure = error.error is AppFailure
            ? error.error as AppFailure
            : mapper.map(error);
        if (shouldEnableDevelopmentHttpDiagnostics(config)) {
          logResponseResult(
            options: error.requestOptions,
            statusCode: error.response?.statusCode,
            backendCode: extractBackendCode(mappedFailure),
          );
        }
        if (error.error is AppFailure) {
          handler.next(error);
          return;
        }
        handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: mappedFailure,
            message: error.message,
          ),
        );
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
});
