import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

class CacheService {
  static const String _prefix = 'app_cache_v1_';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _asyncPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Write JSON-encodable data into local storage
  Future<void> set(String key, Object? jsonObj) async {
    try {
      final prefs = await _asyncPrefs;
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': jsonObj,
      };
      await prefs.setString('$_prefix$key', jsonEncode(wrapper));
    } catch (_) {}
  }

  static const Duration _defaultTtl = Duration(hours: 1);

  bool _isExpired(Map<String, dynamic> decoded, Duration ttl) {
    final ts = decoded['timestamp'];
    if (ts is! int) return true;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age > ttl.inMilliseconds;
  }

  /// Read cached data from local storage
  Future<Map<String, dynamic>?> getMap(
    String key, {
    Duration ttl = _defaultTtl,
  }) async {
    try {
      final prefs = await _asyncPrefs;
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (_isExpired(decoded, ttl)) {
        await prefs.remove('$_prefix$key');
        return null;
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Read cached list from local storage
  Future<List<dynamic>?> getList(
    String key, {
    Duration ttl = _defaultTtl,
  }) async {
    try {
      final prefs = await _asyncPrefs;
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (_isExpired(decoded, ttl)) {
        await prefs.remove('$_prefix$key');
        return null;
      }
      final data = decoded['data'];
      if (data is List) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Remove cached key
  Future<void> remove(String key) async {
    try {
      final prefs = await _asyncPrefs;
      await prefs.remove('$_prefix$key');
    } catch (_) {}
  }

  /// Clear all cached app data
  Future<void> clear() async {
    try {
      final prefs = await _asyncPrefs;
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
