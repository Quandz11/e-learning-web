String? normalizeVietnamesePhone(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  var normalized = trimmed.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
  if (normalized.startsWith('+')) {
    normalized = normalized.substring(1);
  }
  if (normalized.startsWith('0') && normalized.length > 1) {
    normalized = '84${normalized.substring(1)}';
  }
  if (!RegExp(r'^\d{9,15}$').hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

String? validatePhoneInput(String input) {
  if (input.trim().isEmpty) {
    return 'Vui lòng nhập số điện thoại.';
  }
  if (normalizeVietnamesePhone(input) == null) {
    return 'Số điện thoại không hợp lệ.';
  }
  return null;
}
