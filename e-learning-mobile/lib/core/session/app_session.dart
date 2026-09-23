import 'dart:convert';
class AppSession {
  const AppSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  String? claim(String key) {
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(accessToken.split('.')[1]))));
      return payload is Map ? payload[key]?.toString() : null;
    } catch (_) { return null; }
  }

  String? get userId => claim('sub');
  String? get sessionId => claim('sid');
  String? get role => claim('role') ?? claim('http://schemas.microsoft.com/ws/2008/06/identity/claims/role');

  bool isExpiredAt(DateTime now) {
    return !expiresAt.isAfter(now.toUtc());
  }

  AppSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AppSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
