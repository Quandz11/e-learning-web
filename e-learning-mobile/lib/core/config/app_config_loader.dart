import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/network/dev_network_support.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfigLoader {
  static const _supportedAppSchemes = {'skvi', 'skvi-dev', 'skvi-staging'};
  static const _supportedHosts = {'nhinanchualanh.vn', 'www.nhinanchualanh.vn'};

  static Future<AppConfig> load({String? selectedFlavor}) async {
    final flavor = AppFlavor.parse(
      selectedFlavor ??
          const String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev'),
    );

    final dotenv = DotEnv();
    await dotenv.load(fileName: _fileNameFor(flavor));

    return fromEnvironmentMap(dotenv.env);
  }

  static AppConfig fromEnvironmentMap(Map<String, String> env) {
    const dartDefineApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    final rawApiBaseUrl = dartDefineApiBaseUrl.isNotEmpty
        ? dartDefineApiBaseUrl
        : _readRequired(env, 'API_BASE_URL');
    final rawFlavor = _readRequired(env, 'APP_FLAVOR');
    final rawPaymentReturnUrl = _readRequired(env, 'PAYMENT_RETURN_URL');
    final rawPaymentCancelUrl = _readRequired(env, 'PAYMENT_CANCEL_URL');

    final flavor = AppFlavor.parse(rawFlavor);
    final apiBaseUrl = normalizeApiBaseUrlForPlatform(
      _parseApiBaseUrl(rawApiBaseUrl),
    );
    final paymentReturnUrl = _parseCallbackUrl(
      rawPaymentReturnUrl,
      name: 'PAYMENT_RETURN_URL',
    );
    final paymentCancelUrl = _parseCallbackUrl(
      rawPaymentCancelUrl,
      name: 'PAYMENT_CANCEL_URL',
    );

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      flavor: flavor,
      paymentReturnUrl: paymentReturnUrl,
      paymentCancelUrl: paymentCancelUrl,
    );
  }

  static String _fileNameFor(AppFlavor flavor) {
    return switch (flavor) {
      AppFlavor.dev => 'assets/env/.env.dev',
      AppFlavor.staging => 'assets/env/.env.staging',
      AppFlavor.prod => 'assets/env/.env.prod',
    };
  }

  static String _readRequired(Map<String, String> env, String key) {
    final value = env[key]?.trim() ?? '';
    if (value.isEmpty) {
      throw AppConfigException(
        '$key is missing.',
        userMessage: 'The app configuration is incomplete.',
      );
    }
    return value;
  }

  static Uri _parseApiBaseUrl(String rawValue) {
    final uri = Uri.tryParse(rawValue.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const AppConfigException(
        'API_BASE_URL must be an absolute URL.',
        userMessage: 'The app configuration is invalid.',
      );
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw const AppConfigException(
        'API_BASE_URL must use http or https.',
        userMessage: 'The app configuration is invalid.',
      );
    }
    return uri;
  }

  static Uri _parseCallbackUrl(String rawValue, {required String name}) {
    final uri = Uri.tryParse(rawValue.trim());
    if (uri == null || !uri.hasScheme) {
      throw AppConfigException(
        '$name must be an absolute URL.',
        userMessage: 'The app configuration is invalid.',
      );
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (!uri.hasAuthority || uri.host.trim().isEmpty) {
        throw AppConfigException(
          '$name must include a valid host.',
          userMessage: 'The app configuration is invalid.',
        );
      }
      if (!_supportedHosts.contains(uri.host.toLowerCase())) {
        throw AppConfigException(
          '$name host is not supported: ${uri.host}',
          userMessage: 'The app configuration is invalid.',
        );
      }
      return uri;
    }

    if (_supportedAppSchemes.contains(uri.scheme)) {
      return uri;
    }

    throw AppConfigException(
      '$name uses an unsupported scheme: ${uri.scheme}',
      userMessage: 'The app configuration is invalid.',
    );
  }
}
