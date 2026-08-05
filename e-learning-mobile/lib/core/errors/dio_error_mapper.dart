import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';

class DioErrorMapper {
  const DioErrorMapper();

  AppFailure map(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppFailure(
          type: AppFailureType.timeout,
          message: 'The request timed out. Please try again.',
          statusCode: error.response?.statusCode,
          debugDetails: error.message,
          originalCause: error,
        );
      case DioExceptionType.cancel:
        return AppFailure(
          type: AppFailureType.cancelled,
          message: 'The request was cancelled.',
          statusCode: error.response?.statusCode,
          debugDetails: error.message,
          originalCause: error,
        );
      case DioExceptionType.connectionError:
        return AppFailure(
          type: _isNetworkUnavailable(error.error)
              ? AppFailureType.networkUnavailable
              : AppFailureType.connectionFailure,
          message: 'A network connection could not be established.',
          statusCode: error.response?.statusCode,
          debugDetails: error.message,
          originalCause: error,
        );
      case DioExceptionType.badResponse:
        return _mapBadResponse(error);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return AppFailure(
          type: AppFailureType.unknown,
          message: 'Something went wrong. Please try again.',
          statusCode: error.response?.statusCode,
          debugDetails: error.message,
          originalCause: error,
        );
    }
  }

  AppFailure _mapBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final envelope = _extractEnvelope(body);

    final fallbackMessage = switch (statusCode) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have access to this action.',
      404 => 'The requested resource was not found.',
      _ when (statusCode ?? 0) >= 500 =>
        'The server is unavailable right now. Please try again later.',
      _ => 'The request could not be completed.',
    };

    return AppFailure(
      type: _mapStatusToType(
        statusCode,
        envelope.code,
        envelope.validationErrors,
      ),
      message: envelope.message ?? fallbackMessage,
      statusCode: statusCode,
      backendCode: envelope.code,
      validationErrors: envelope.validationErrors,
      debugDetails: body?.toString(),
      originalCause: error,
    );
  }

  _ErrorEnvelope _extractEnvelope(dynamic body) {
    if (body is Map<String, dynamic>) {
      final code = body['code']?.toString();
      final message = body['message']?.toString();
      final errors = _extractValidationErrors(body['errors']);
      return _ErrorEnvelope(
        code: code,
        message: message,
        validationErrors: errors,
      );
    }

    if (body is Map) {
      final normalized = body.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return _extractEnvelope(normalized);
    }

    if (body == null || body.toString().trim().isEmpty) {
      return const _ErrorEnvelope();
    }

    return _ErrorEnvelope(message: body.toString());
  }

  Map<String, List<String>>? _extractValidationErrors(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      final mapped = <String, List<String>>{};
      for (final entry in value.entries) {
        mapped[entry.key] = _coerceMessages(entry.value);
      }
      return mapped;
    }
    if (value is Map) {
      final mapped = <String, List<String>>{};
      for (final entry in value.entries) {
        mapped[entry.key.toString()] = _coerceMessages(entry.value);
      }
      return mapped;
    }
    return {'general': _coerceMessages(value)};
  }

  List<String> _coerceMessages(dynamic value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    if (value == null) {
      return const [];
    }
    return [value.toString()];
  }

  AppFailureType _mapStatusToType(
    int? statusCode,
    String? code,
    Map<String, List<String>>? validationErrors,
  ) {
    if (statusCode == 401) {
      return AppFailureType.unauthorized;
    }
    if (statusCode == 403) {
      return AppFailureType.forbidden;
    }
    if (statusCode == 404) {
      return AppFailureType.notFound;
    }
    if (statusCode == 400 &&
        validationErrors != null &&
        validationErrors.isNotEmpty) {
      return AppFailureType.validation;
    }
    if (statusCode == 400 && code != null && code.isNotEmpty) {
      return AppFailureType.business;
    }
    if (statusCode != null && statusCode >= 500) {
      return AppFailureType.server;
    }
    if (statusCode != null && statusCode >= 400) {
      return AppFailureType.business;
    }
    return AppFailureType.malformedResponse;
  }

  bool _isNetworkUnavailable(Object? error) {
    return error is SocketException || error is TimeoutException;
  }
}

class _ErrorEnvelope {
  const _ErrorEnvelope({this.code, this.message, this.validationErrors});

  final String? code;
  final String? message;
  final Map<String, List<String>>? validationErrors;
}
