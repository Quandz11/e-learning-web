import 'route_paths.dart';

String? mapExternalDeepLinkToRoute(Uri uri) {
  if (uri.scheme.isEmpty) {
    return null;
  }

  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final normalizedPath = _normalizePath(uri.path);
  final isCustomScheme =
      scheme == 'skvi' || scheme == 'skvi-dev' || scheme == 'skvi-staging';

  final isCustomSchemePaymentRoute =
      isCustomScheme &&
      ((host == 'payment' && normalizedPath == '/result') ||
          host == 'payment-result' ||
          normalizedPath == '/payment/result' ||
          normalizedPath == '/payment-result');

  final isUniversalLinkPaymentRoute =
      (scheme == 'https' || (scheme == 'http' && host == 'localhost')) &&
      _isTrustedUniversalHost(host) &&
      (normalizedPath == '/payment/result' ||
          normalizedPath == '/payment-result');

  if (!isCustomSchemePaymentRoute && !isUniversalLinkPaymentRoute) {
    return null;
  }

  if (uri.query.isEmpty) {
    return RoutePaths.paymentResult;
  }

  return '${RoutePaths.paymentResult}?${uri.query}';
}

bool _isTrustedUniversalHost(String host) {
  if (host == 'nhinanchualanh.vn' ||
      host == 'www.nhinanchualanh.vn' ||
      host == 'localhost') {
    return true;
  }

  return host.endsWith('.nhinanchualanh.vn');
}

String _normalizePath(String path) {
  if (path.isEmpty) {
    return '/';
  }

  var normalized = path.toLowerCase();
  if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }

  while (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  return normalized;
}
