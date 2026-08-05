import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/errors/dio_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DioErrorMapper();

  DioException buildError({
    DioExceptionType type = DioExceptionType.badResponse,
    int? statusCode,
    Object? data,
    Object? error,
  }) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: statusCode == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: statusCode,
              data: data,
            ),
      type: type,
      error: error,
    );
  }

  test('maps structured error body', () {
    final failure = mapper.map(
      buildError(
        statusCode: 400,
        data: {
          'code': 'AUTH_INVALID',
          'message': 'Bad input',
          'errors': {
            'email': ['Required'],
          },
        },
      ),
    );

    expect(failure.type, AppFailureType.validation);
    expect(failure.backendCode, 'AUTH_INVALID');
    expect(failure.validationErrors?['email'], ['Required']);
  });

  test('maps simple message body', () {
    final failure = mapper.map(
      buildError(statusCode: 400, data: {'message': 'Nope'}),
    );

    expect(failure.type, AppFailureType.business);
    expect(failure.message, 'Nope');
  });

  test('maps timeout', () {
    final failure = mapper.map(
      buildError(type: DioExceptionType.receiveTimeout),
    );

    expect(failure.type, AppFailureType.timeout);
  });

  test('maps network failure', () {
    final failure = mapper.map(
      buildError(
        type: DioExceptionType.connectionError,
        error: const FormatException('offline'),
      ),
    );

    expect({
      AppFailureType.connectionFailure,
      AppFailureType.networkUnavailable,
    }, contains(failure.type));
  });

  test('maps unauthorized', () {
    final failure = mapper.map(buildError(statusCode: 401, data: {}));
    expect(failure.type, AppFailureType.unauthorized);
  });

  test('maps empty response body', () {
    final failure = mapper.map(buildError(statusCode: 500, data: null));
    expect(failure.type, AppFailureType.server);
  });

  test('maps malformed body', () {
    final failure = mapper.map(buildError(statusCode: 400, data: 'weird'));
    expect(failure.message, 'weird');
  });

  test('maps server error', () {
    final failure = mapper.map(buildError(statusCode: 503, data: {}));
    expect(failure.type, AppFailureType.server);
  });
}
