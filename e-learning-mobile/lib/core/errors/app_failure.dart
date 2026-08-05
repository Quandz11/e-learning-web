enum AppFailureType {
  networkUnavailable,
  connectionFailure,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  validation,
  business,
  server,
  malformedResponse,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure({
    required this.type,
    required this.message,
    this.statusCode,
    this.backendCode,
    this.validationErrors,
    this.debugDetails,
    this.originalCause,
  });

  final AppFailureType type;
  final String message;
  final int? statusCode;
  final String? backendCode;
  final Map<String, List<String>>? validationErrors;
  final String? debugDetails;
  final Object? originalCause;

  bool get isUnauthorized => type == AppFailureType.unauthorized;
}
