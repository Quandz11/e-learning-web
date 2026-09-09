import 'package:e_learning_mobile/core/errors/app_failure.dart';

String learningFailureMessage(AppFailure? failure, {required String fallback}) {
  if (failure == null) {
    return fallback;
  }

  if (failure.type == AppFailureType.validation ||
      failure.type == AppFailureType.business) {
    return failure.message;
  }

  return switch (failure.type) {
    AppFailureType.networkUnavailable ||
    AppFailureType.connectionFailure => 'Không có kết nối mạng ổn định.',
    AppFailureType.timeout => 'Máy chủ phản hồi quá chậm. Vui lòng thử lại.',
    AppFailureType.unauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    AppFailureType.forbidden => 'Bạn chưa có quyền truy cập nội dung này.',
    AppFailureType.notFound => 'Không tìm thấy nội dung cần hiển thị.',
    AppFailureType.server => 'Máy chủ đang bận. Vui lòng thử lại sau.',
    AppFailureType.malformedResponse =>
      'Dữ liệu trả về không hợp lệ. Vui lòng thử lại.',
    _ => fallback,
  };
}

String stripHtml(String value) {
  return _decodeBasicHtmlEntities(
    value,
  ).replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String formatLearningDuration(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }
  return '$minutes:${_twoDigits(seconds)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _decodeBasicHtmlEntities(String value) {
  return value.replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z]+);'), (
    match,
  ) {
    final entity = match.group(1);
    if (entity == null) {
      return match.group(0) ?? '';
    }

    final named = switch (entity) {
      'amp' => '&',
      'apos' => "'",
      'gt' => '>',
      'lt' => '<',
      'nbsp' => ' ',
      'quot' => '"',
      _ => null,
    };
    if (named != null) {
      return named;
    }

    final codePoint = entity.startsWith('#x')
        ? int.tryParse(entity.substring(2), radix: 16)
        : entity.startsWith('#')
        ? int.tryParse(entity.substring(1))
        : null;
    if (codePoint == null) {
      return match.group(0) ?? '';
    }

    return String.fromCharCode(codePoint);
  });
}
