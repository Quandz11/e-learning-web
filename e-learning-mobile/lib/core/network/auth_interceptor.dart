import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SessionRepository sessionRepository,
    required SessionController sessionController,
  }) : _sessionRepository = sessionRepository,
       _sessionController = sessionController,
       _dio = dio;

  final SessionRepository _sessionRepository;
  final SessionController _sessionController;
  final Dio _dio;

  Future<AppSession>? _inFlightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = await _sessionRepository.readStoredSession();
    if (session != null && session.accessToken.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    final activeRefresh = _inFlightRefresh ??= _sessionRepository
        .refreshStoredSession();

    try {
      final refreshed = await activeRefresh;
      _sessionController.syncSession(refreshed);
      final retryResponse = await _retry(
        err.requestOptions,
        refreshed.accessToken,
      );
      handler.resolve(retryResponse);
    } catch (_) {
      await _sessionController.clearSession();
      handler.next(err);
    } finally {
      if (identical(_inFlightRefresh, activeRefresh)) {
        _inFlightRefresh = null;
      }
    }
  }

  bool _shouldRefresh(DioException err) {
    final options = err.requestOptions;
    final path = options.path.toLowerCase();

    if (err.response?.statusCode != 401) {
      return false;
    }
    if (options.extra['auth_retry_attempted'] == true) {
      return false;
    }
    if (path.contains('/auth/')) {
      return false;
    }
    if (_isNonRepeatableMultipart(options)) {
      return false;
    }
    return true;
  }

  bool _isNonRepeatableMultipart(RequestOptions options) {
    final contentType =
        options.contentType ?? options.headers['Content-Type']?.toString();
    if (contentType != null && contentType.contains('multipart/form-data')) {
      return true;
    }
    return options.data is FormData;
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    final updatedHeaders = Map<String, dynamic>.from(requestOptions.headers);
    updatedHeaders['Authorization'] = 'Bearer $accessToken';

    final options = Options(
      method: requestOptions.method,
      headers: updatedHeaders,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      contentType: requestOptions.contentType,
      responseType: requestOptions.responseType,
      validateStatus: requestOptions.validateStatus,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      extra: {...requestOptions.extra, 'auth_retry_attempted': true},
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }
}
