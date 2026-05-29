import 'package:dio/dio.dart';

import '../../errors/error_mapper.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: ErrorMapper.map(err),
        type: err.type,
        message: err.message,
      ),
    );
  }
}
