import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { dev, staging, prod }

extension AppFlavorX on AppFlavor {
  String get value => switch (this) {
    AppFlavor.dev => 'dev',
    AppFlavor.staging => 'staging',
    AppFlavor.prod => 'prod',
  };

  static AppFlavor fromValue(String value) {
    return switch (value.toLowerCase()) {
      'dev' => AppFlavor.dev,
      'staging' => AppFlavor.staging,
      'prod' => AppFlavor.prod,
      _ => AppFlavor.dev,
    };
  }
}

final appFlavorProvider = Provider<AppFlavor>((_) => AppFlavor.dev);
