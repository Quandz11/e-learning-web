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
          message: 'Yêu cầu đã quá thời gian chờ. Vui lòng thử lại.',
          statusCode: error.response?.statusCode,
          debugDetails: error.message,
          originalCause: error,
        );
      case DioExceptionType.cancel:
        return AppFailure(
          type: AppFailureType.cancelled,
          message: 'Yêu cầu đã bị hủy.',
          statusCode: error.response?.statusCode,
          debugDetails: error.message,
          originalCause: error,
        );
      case DioExceptionType.connectionError:
        return AppFailure(
          type: _isNetworkUnavailable(error.error)
              ? AppFailureType.networkUnavailable
              : AppFailureType.connectionFailure,
          message:
              'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
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
          message: 'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
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
      401 =>
        'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy tài nguyên yêu cầu.',
      429 => 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau ít phút.',
      _ when (statusCode ?? 0) >= 500 =>
        'Máy chủ đang bảo trì hoặc gặp sự cố. Vui lòng thử lại sau.',
      _ => 'Không thể hoàn thành yêu cầu. Vui lòng thử lại sau.',
    };

    final resolvedMessage = _localizeMessage(
      envelope.code,
      envelope.message,
      fallbackMessage,
    );

    return AppFailure(
      type: _mapStatusToType(
        statusCode,
        envelope.code,
        envelope.validationErrors,
      ),
      message: resolvedMessage,
      statusCode: statusCode,
      backendCode: envelope.code,
      validationErrors: envelope.validationErrors,
      debugDetails: body?.toString(),
      originalCause: error,
    );
  }

  String _localizeMessage(String? code, String? message, String fallback) {
    if (code != null) {
      final byCode = _mapBackendCode(code);
      if (byCode != null) return byCode;
    }
    if (message != null && message.trim().isNotEmpty) {
      final normalized = message.trim();
      final byEnglish = _mapEnglishMessage(normalized);
      if (byEnglish != null) return byEnglish;
      return normalized;
    }
    return fallback;
  }

  String? _mapBackendCode(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'AUTH_INVALID_CREDENTIALS':
      case 'AUTH_LOGIN_FAILED':
        return 'Email, số điện thoại hoặc mật khẩu không chính xác.';
      case 'AUTH_ACCOUNT_DELETED':
        return 'Tài khoản đã bị xóa khỏi hệ thống.';
      case 'AUTH_ACCOUNT_NOT_ACTIVE':
        return 'Tài khoản chưa được kích hoạt. Vui lòng xác thực mã OTP.';
      case 'AUTH_ACCOUNT_INACTIVE':
        return 'Tài khoản hiện đang bị tạm khóa hoặc ngưng hoạt động.';
      case 'AUTH_ACCOUNT_NOT_VERIFIED':
        return 'Tài khoản chưa được xác thực.';
      case 'AUTH_PHONE_NOT_VERIFIED':
        return 'Số điện thoại chưa được xác thực.';
      case 'AUTH_OTP_INVALID':
        return 'Mã xác thực OTP không chính xác.';
      case 'AUTH_OTP_EXPIRED':
        return 'Mã xác thực OTP đã hết hạn.';
      case 'AUTH_RESEND_OTP_FAILED':
        return 'Gửi lại mã xác thực thất bại. Vui lòng thử lại sau.';
      case 'AUTH_REGISTER_INVALID':
        return 'Thông tin đăng ký không hợp lệ.';
      case 'AUTH_USER_NOT_FOUND':
        return 'Không tìm thấy thông tin tài khoản người dùng.';
      case 'AUTH_UNAUTHORIZED':
        return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.';
      case 'AUTH_REFRESH_TOKEN_MISSING':
        return 'Không tìm thấy phiên làm việc để làm mới mã truy cập.';
      case 'AUTH_REFRESH_FAILED':
        return 'Làm mới phiên đăng nhập thất bại. Vui lòng đăng nhập lại.';
      case 'AUTH_SESSION_NOT_FOUND':
        return 'Không tìm thấy phiên đăng nhập.';
      case 'AUTH_SESSION_REVOKED':
        return 'Phiên đăng nhập đã bị thu hồi.';
      case 'AUTH_GET_SESSIONS_FAILED':
        return 'Không thể tải danh sách phiên đăng nhập.';
      case 'AUTH_REVOKE_SESSION_FAILED':
        return 'Không thể thu hồi phiên đăng nhập.';
      case 'AUTH_REVOKE_ALL_SESSIONS_FAILED':
        return 'Không thể đăng xuất các thiết bị khác.';
      case 'AUTH_2FA_SETUP_FAILED':
        return 'Không thể khởi tạo mã bảo mật 2FA.';
      case 'AUTH_2FA_ENABLE_FAILED':
        return 'Kích hoạt bảo mật 2FA thất bại.';
      case 'AUTH_2FA_DISABLE_FAILED':
        return 'Tắt bảo mật 2FA thất bại.';
      case 'AUTH_2FA_VERIFY_FAILED':
        return 'Mã bảo mật hai lớp (2FA) không chính xác.';
      case 'TOO_MANY_REQUESTS':
        return 'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.';
      default:
        return null;
    }
  }

  String? _mapEnglishMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid credential') ||
        lower.contains('invalid email or password')) {
      return 'Email, số điện thoại hoặc mật khẩu không chính xác.';
    }
    if (lower.contains('account is deleted') ||
        lower.contains('account has been deleted')) {
      return 'Tài khoản đã bị xóa khỏi hệ thống.';
    }
    if (lower.contains('not active') || lower.contains('verify otp')) {
      return 'Tài khoản chưa được kích hoạt. Vui lòng xác thực mã OTP.';
    }
    if (lower.contains('phone number is not verified') ||
        lower.contains('phone not verified')) {
      return 'Số điện thoại chưa được xác thực.';
    }
    if (lower.contains('user not found')) {
      return 'Không tìm thấy thông tin tài khoản người dùng.';
    }
    if (lower.contains('invalid otp')) {
      return 'Mã xác thực OTP không chính xác.';
    }
    if (lower.contains('otp has expired') ||
        lower.contains('otp does not exist or has expired')) {
      return 'Mã xác thực OTP đã hết hạn.';
    }
    if (lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'Thông tin này đã được đăng ký trong hệ thống.';
    }
    if (lower.contains('too many requests')) {
      return 'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.';
    }
    if (lower.contains('invalid 2fa') || lower.contains('invalid code')) {
      return 'Mã xác thực không chính xác.';
    }
    return null;
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
