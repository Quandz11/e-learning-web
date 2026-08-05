import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor {
  dev,
  staging,
  prod;

  String get value => switch (this) {
    AppFlavor.dev => 'dev',
    AppFlavor.staging => 'staging',
    AppFlavor.prod => 'prod',
  };

  static AppFlavor parse(String raw) {
    final normalized = raw.trim().toLowerCase();
    return AppFlavor.values.firstWhere(
      (flavor) => flavor.value == normalized,
      orElse: () => throw AppConfigException(
        'Unsupported app flavor: $raw',
        userMessage: 'The app configuration is invalid.',
      ),
    );
  }
}

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.flavor,
    required this.paymentReturnUrl,
    required this.paymentCancelUrl,
  });

  final Uri apiBaseUrl;
  final AppFlavor flavor;
  final Uri paymentReturnUrl;
  final Uri paymentCancelUrl;
}

class AppConfigException implements Exception {
  const AppConfigException(this.message, {required this.userMessage});

  final String message;
  final String userMessage;

  @override
  String toString() => message;
}

final appConfigProvider = Provider<AppConfig>((_) {
  throw const AppConfigException(
    'AppConfig provider was read before initialization.',
    userMessage: 'The app could not start. Please try again later.',
  );
});
