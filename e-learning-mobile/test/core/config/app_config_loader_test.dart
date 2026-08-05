import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/config/app_config_loader.dart';
import 'package:e_learning_mobile/core/network/dev_network_support.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfigLoader', () {
    test('loads valid configuration', () {
      final config = AppConfigLoader.fromEnvironmentMap({
        'API_BASE_URL': 'https://api.example.com/api',
        'APP_FLAVOR': 'staging',
        'PAYMENT_RETURN_URL': 'skvi-staging://payment/result',
        'PAYMENT_CANCEL_URL': 'https://nhinanchualanh.vn/payment/cancel',
      });

      expect(config.apiBaseUrl.toString(), 'https://api.example.com/api');
      expect(config.flavor, AppFlavor.staging);
      expect(config.paymentReturnUrl.scheme, 'skvi-staging');
      expect(config.paymentCancelUrl.host, 'nhinanchualanh.vn');
    });

    test('throws when API base URL is missing', () {
      expect(
        () => AppConfigLoader.fromEnvironmentMap({
          'APP_FLAVOR': 'dev',
          'PAYMENT_RETURN_URL': 'skvi://payment/result',
          'PAYMENT_CANCEL_URL': 'skvi://payment/cancel',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('throws when API base URL is invalid', () {
      expect(
        () => AppConfigLoader.fromEnvironmentMap({
          'API_BASE_URL': 'not-a-url',
          'APP_FLAVOR': 'dev',
          'PAYMENT_RETURN_URL': 'skvi://payment/result',
          'PAYMENT_CANCEL_URL': 'skvi://payment/cancel',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('throws when payment callback values are missing', () {
      expect(
        () => AppConfigLoader.fromEnvironmentMap({
          'API_BASE_URL': 'https://api.example.com/api',
          'APP_FLAVOR': 'dev',
          'PAYMENT_RETURN_URL': 'skvi://payment/result',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('throws when app flavor is unsupported', () {
      expect(
        () => AppConfigLoader.fromEnvironmentMap({
          'API_BASE_URL': 'https://api.example.com/api',
          'APP_FLAVOR': 'qa',
          'PAYMENT_RETURN_URL': 'skvi://payment/result',
          'PAYMENT_CANCEL_URL': 'skvi://payment/cancel',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('normalizes localhost for Android emulator only', () {
      final androidUri = normalizeApiBaseUrlForPlatform(
        Uri.parse('https://localhost:7145/api'),
        targetPlatform: TargetPlatform.android,
        isWeb: false,
      );
      final windowsUri = normalizeApiBaseUrlForPlatform(
        Uri.parse('https://localhost:7145/api'),
        targetPlatform: TargetPlatform.windows,
        isWeb: false,
      );

      expect(androidUri.host, '10.0.2.2');
      expect(windowsUri.host, 'localhost');
    });
  });
}
