import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/network/dev_network_support.dart';
import 'package:e_learning_mobile/core/storage/session_storage.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_session.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    storage: ref.read(sessionStorageProvider),
    config: ref.read(appConfigProvider),
  );
});

class SessionRepository {
  SessionRepository({
    required SessionStorage storage,
    required AppConfig config,
    Dio? refreshDio,
  }) : _storage = storage,
       _config = config,
       _refreshDio =
           refreshDio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl.toString(),
               headers: const {'Content-Type': 'application/json'},
               connectTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 20),
             ),
           ) {
    configureDevelopmentTransport(_refreshDio, config);
    if (shouldEnableDevelopmentHttpDiagnostics(config)) {
      _refreshDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            logRequestStart(options);
            handler.next(options);
          },
          onResponse: (response, handler) {
            logResponseResult(
              options: response.requestOptions,
              statusCode: response.statusCode,
              backendCode: extractBackendCodeFromResponseData(response.data),
            );
            handler.next(response);
          },
          onError: (error, handler) {
            logResponseResult(
              options: error.requestOptions,
              statusCode: error.response?.statusCode,
              backendCode: extractBackendCodeFromResponseData(
                error.response?.data,
              ),
            );
            handler.next(error);
          },
        ),
      );
    }
  }

  final SessionStorage _storage;
  final AppConfig _config;
  final Dio _refreshDio;

  int _generation = 0;
  int get generation => _generation;
  Future<void> _writes = Future.value();
  Future<AppSession>? _refresh;

  Future<void> _write(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> clear() {
    _generation++;
    return _write(_storage.clear);
  }

  Future<AppSession?> readStoredSession() => _storage.read();

  Future<void> writeSession(AppSession session) {
    _generation++;
    return _write(() => _storage.write(session));
  }

  Future<AppSession?> restoreSession() async {
    final stored = await _storage.read();
    if (stored == null) {
      return null;
    }

    if (stored.isExpiredAt(DateTime.now().toUtc())) {
      try {
        return await refreshSession(stored);
      } catch (_) {
        await clear();
        return null;
      }
    }

    return stored;
  }

  Future<AppSession> refreshStoredSession() async {
    final current = await _storage.read();
    if (current == null) {
      throw const SessionRefreshException('No stored session.');
    }
    final pending = _refresh ??= refreshSession(current);
    try { return await pending; }
    finally { if (identical(_refresh, pending)) _refresh = null; }
  }

  Future<AppSession> refreshSession(AppSession session) async {
    final generation = _generation;
    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': session.refreshToken},
    );

    final data = response.data;
    if (data == null) {
      await clear();
      throw const SessionRefreshException('Refresh response body was empty.');
    }

    final accessToken = data['accessToken']?.toString().trim() ?? '';
    final refreshToken = data['refreshToken']?.toString().trim() ?? '';
    final expiresAtRaw = data['expiresAt']?.toString().trim() ?? '';
    final expiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();

    if (accessToken.isEmpty || refreshToken.isEmpty || expiresAt == null) {
      await clear();
      throw const SessionRefreshException('Refresh response was malformed.');
    }

    final refreshed = AppSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
    await _write(() async {
      if (_generation != generation) throw const SessionRefreshException('Session changed during refresh.');
      await _storage.write(refreshed);
    });
    if (_generation != generation) throw const SessionRefreshException('Session changed during refresh.');
    return refreshed;
  }

  bool isPaymentCallback(Uri uri) {
    return uri == _config.paymentReturnUrl || uri == _config.paymentCancelUrl;
  }
}

class SessionRefreshException implements Exception {
  const SessionRefreshException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SessionRepositoryFailure extends AppFailure {
  const SessionRepositoryFailure({
    required super.type,
    required super.message,
    super.statusCode,
    super.backendCode,
    super.validationErrors,
    super.debugDetails,
    super.originalCause,
  });
}
