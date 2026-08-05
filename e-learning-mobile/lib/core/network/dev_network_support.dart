import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:flutter/foundation.dart';

const _androidEmulatorLoopbackHost = '10.0.2.2';
const _loopbackHosts = {
  'localhost',
  '127.0.0.1',
  '::1',
  _androidEmulatorLoopbackHost,
};

Uri normalizeApiBaseUrlForPlatform(
  Uri uri, {
  TargetPlatform? targetPlatform,
  bool isWeb = kIsWeb,
}) {
  if (isWeb ||
      (targetPlatform ?? defaultTargetPlatform) != TargetPlatform.android) {
    return uri;
  }
  if (_loopbackHosts.contains(uri.host.toLowerCase())) {
    return uri.replace(host: _androidEmulatorLoopbackHost);
  }
  return uri;
}

void configureDevelopmentTransport(Dio dio, AppConfig config) {
  if (kIsWeb) {
    return;
  }

  final host = config.apiBaseUrl.host.toLowerCase();
  final allowSelfSigned =
      config.flavor == AppFlavor.dev &&
      config.apiBaseUrl.scheme == 'https' &&
      _loopbackHosts.contains(host);

  if (!allowSelfSigned) {
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (certificate, requestHost, requestPort) {
        return _loopbackHosts.contains(requestHost.toLowerCase());
      };
      return client;
    },
  );
}

bool shouldEnableDevelopmentHttpDiagnostics(AppConfig config) {
  return kDebugMode && config.flavor == AppFlavor.dev;
}

void logRequestStart(RequestOptions options) {
  debugPrint('[HTTP] ${options.method.toUpperCase()} ${options.path}');
}

void logResponseResult({
  required RequestOptions options,
  int? statusCode,
  String? backendCode,
}) {
  final statusLabel = statusCode?.toString() ?? 'no-status';
  final codeLabel = backendCode != null && backendCode.trim().isNotEmpty
      ? ' code=$backendCode'
      : '';
  debugPrint(
    '[HTTP] $statusLabel ${options.method.toUpperCase()} ${options.path}$codeLabel',
  );
}

String? extractBackendCode(Object? error) {
  if (error is AppFailure) {
    return error.backendCode;
  }
  return null;
}

String? extractBackendCodeFromResponseData(Object? data) {
  if (data is Map<String, dynamic>) {
    return data['code']?.toString();
  }
  if (data is Map) {
    return data['code']?.toString();
  }
  return null;
}
