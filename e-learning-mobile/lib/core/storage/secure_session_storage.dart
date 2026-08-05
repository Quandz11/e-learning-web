import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/storage/session_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorageKeys {
  static const accessToken = 'session.access_token';
  static const refreshToken = 'session.refresh_token';
  static const expiresAt = 'session.expires_at';
}

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage();
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SecureSessionStorage(ref.read(flutterSecureStorageProvider));
});

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() async {
    await _storage.delete(key: SessionStorageKeys.accessToken);
    await _storage.delete(key: SessionStorageKeys.refreshToken);
    await _storage.delete(key: SessionStorageKeys.expiresAt);
  }

  @override
  Future<AppSession?> read() async {
    final accessToken = await _storage.read(
      key: SessionStorageKeys.accessToken,
    );
    final refreshToken = await _storage.read(
      key: SessionStorageKeys.refreshToken,
    );
    final expiresAtRaw = await _storage.read(key: SessionStorageKeys.expiresAt);

    if (accessToken == null || refreshToken == null || expiresAtRaw == null) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      await clear();
      return null;
    }

    return AppSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> write(AppSession session) async {
    await _storage.write(
      key: SessionStorageKeys.accessToken,
      value: session.accessToken,
    );
    await _storage.write(
      key: SessionStorageKeys.refreshToken,
      value: session.refreshToken,
    );
    await _storage.write(
      key: SessionStorageKeys.expiresAt,
      value: session.expiresAt.toUtc().toIso8601String(),
    );
  }
}
