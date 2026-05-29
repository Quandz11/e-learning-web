import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_tokens.dart';
import '../../auth/token_store.dart';
import '../../telemetry/app_logger.dart';
import '../../config/env_loader.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;
  Future<AuthTokens?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _ref.read(tokenStoreProvider).read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path.contains('/auth/refresh')) {
      handler.next(err);
      return;
    }

    final activeRefresh = _refreshFuture ??= _refreshTokens();
    try {
      final refreshed = await activeRefresh;
      if (refreshed == null) {
        handler.next(err);
        return;
      }

      final response = await _retryWithToken(
        err.requestOptions,
        refreshed.accessToken,
      );
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    } finally {
      if (identical(_refreshFuture, activeRefresh)) {
        _refreshFuture = null;
      }
    }
  }

  Future<AuthTokens?> _refreshTokens() async {
    final tokenStore = _ref.read(tokenStoreProvider);
    final logger = _ref.read(appLoggerProvider);

    try {
      final current = await tokenStore.read();
      if (current == null) {
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(baseUrl: _ref.read(appEnvProvider).apiBaseUrl),
      );
      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );

      final accessToken =
          refreshResponse.data?['accessToken']?.toString() ?? '';
      if (accessToken.isEmpty) {
        return null;
      }

      final refreshToken = refreshResponse.data?['refreshToken']?.toString();
      final expiresAtRaw = refreshResponse.data?['expiresAt']?.toString();
      final expiresAt =
          DateTime.tryParse(expiresAtRaw ?? '') ??
          DateTime.now().add(const Duration(hours: 1));

      final refreshed = AuthTokens(
        accessToken: accessToken,
        refreshToken: (refreshToken == null || refreshToken.isEmpty)
            ? current.refreshToken
            : refreshToken,
        expiresAt: expiresAt,
      );

      await tokenStore.save(refreshed);
      return refreshed;
    } catch (error, stackTrace) {
      logger.warn('Token refresh failed: $error');
      logger.error('Token refresh stack', error, stackTrace);
      await tokenStore.clear();
      return null;
    }
  }

  Future<Response<dynamic>> _retryWithToken(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    final retryDio = Dio(
      BaseOptions(baseUrl: _ref.read(appEnvProvider).apiBaseUrl),
    );
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    final options = Options(
      method: requestOptions.method,
      headers: headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      listFormat: requestOptions.listFormat,
      maxRedirects: requestOptions.maxRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      requestEncoder: requestOptions.requestEncoder,
      responseDecoder: requestOptions.responseDecoder,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      extra: Map<String, dynamic>.from(requestOptions.extra),
      validateStatus: requestOptions.validateStatus,
    );

    return retryDio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }
}
