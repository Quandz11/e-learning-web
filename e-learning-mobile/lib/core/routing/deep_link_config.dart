import 'package:e_learning_mobile/core/config/app_config.dart';

class DeepLinkConfig {
  const DeepLinkConfig(this.config);

  final AppConfig config;

  static const supportedHosts = {'nhinanchualanh.vn', 'www.nhinanchualanh.vn'};
  static const supportedSchemes = {'skvi', 'skvi-dev', 'skvi-staging'};

  String? mapExternalUri(Uri uri) {
    if (_matchesExact(uri, config.paymentReturnUrl)) {
      return AppRoutes.paymentReturn;
    }
    if (_matchesExact(uri, config.paymentCancelUrl)) {
      return AppRoutes.paymentCancel;
    }

    if (_isPaymentReturnAlias(uri)) {
      return AppRoutes.paymentReturn;
    }

    return null;
  }

  bool _matchesExact(Uri incoming, Uri configured) {
    return incoming.scheme == configured.scheme &&
        incoming.host == configured.host &&
        incoming.path == configured.path;
  }

  bool _isPaymentReturnAlias(Uri uri) {
    if (uri.scheme == 'https' &&
        supportedHosts.contains(uri.host.toLowerCase())) {
      return uri.path == '/payment/result' || uri.path == '/payment-result';
    }

    if (supportedSchemes.contains(uri.scheme)) {
      final path = uri.path.isEmpty ? '/${uri.host}' : uri.path;
      return path == '/payment/result' || path == '/payment-result';
    }

    return false;
  }
}

abstract final class AppRoutes {
  static const devComponents = '/dev/components';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const verifyOtp = '/verify-otp';
  static const appRoot = '/app';
  static const appHome = '/app/home';
  static const appLearning = '/app/learning';
  static const appCommunity = '/app/community';
  static const appProfile = '/app/profile';
  static const protectedHome = appRoot;
  static const paymentReturn = '/payment-return';
  static const paymentCancel = '/payment-cancel';

  static const shellDestinations = <String>[
    appHome,
    appLearning,
    appCommunity,
    appProfile,
  ];
}
