import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

@freezed
abstract class ApiError with _$ApiError implements Exception {
  const factory ApiError({
    required String message,
    String? code,
    int? statusCode,
    Map<String, List<String>>? errors,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}
