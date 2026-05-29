import 'dart:io';

import 'package:dio/dio.dart';

import 'api_error.dart';

class ErrorMapper {
  static ApiError map(Object error) {
    if (error is ApiError) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final errorsRaw = data['errors'];
        Map<String, List<String>>? errors;
        if (errorsRaw is Map<String, dynamic>) {
          errors = errorsRaw.map(
            (k, v) => MapEntry(
              k,
              v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
            ),
          );
        }

        return ApiError(
          message: data['message']?.toString() ?? 'Request failed',
          code: data['code']?.toString(),
          statusCode: statusCode,
          errors: errors,
        );
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return const ApiError(message: 'Cannot reach server.');
      }

      return ApiError(
        message: error.message ?? 'Request failed',
        statusCode: statusCode,
      );
    }

    if (error is SocketException) {
      return const ApiError(message: 'Network connection lost.');
    }

    return ApiError(message: error.toString());
  }
}
