import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLogger {
  const AppLogger();

  void info(String message) => _log('INFO', message);
  void warn(String message) => _log('WARN', message);
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', '$message | error=$error');
    if (stackTrace != null) {
      _log('ERROR', stackTrace.toString());
    }
  }

  void _log(String level, String message) {
    if (kDebugMode) {
      debugPrint('[$level] $message');
    }
  }
}

final appLoggerProvider = Provider<AppLogger>((_) => const AppLogger());
