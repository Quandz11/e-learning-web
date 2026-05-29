import 'package:e_learning_mobile/core/routing/deep_link_mapper.dart';
import 'package:e_learning_mobile/core/routing/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapExternalDeepLinkToRoute', () {
    test('maps skvi://payment/result with query to payment result route', () {
      final uri = Uri.parse('skvi://payment/result?orderId=abc&orderCode=123');

      final mapped = mapExternalDeepLinkToRoute(uri);

      expect(mapped, '${RoutePaths.paymentResult}?orderId=abc&orderCode=123');
    });

    test('maps skvi://payment-result with query to payment result route', () {
      final uri = Uri.parse('skvi://payment-result?orderId=abc');

      final mapped = mapExternalDeepLinkToRoute(uri);

      expect(mapped, '${RoutePaths.paymentResult}?orderId=abc');
    });

    test('maps path-style route /payment-result from custom scheme', () {
      final uri = Uri.parse('skvi:///payment-result?orderCode=1');

      final mapped = mapExternalDeepLinkToRoute(uri);

      expect(mapped, '${RoutePaths.paymentResult}?orderCode=1');
    });

    test('returns null for unsupported route', () {
      final uri = Uri.parse('skvi://other/path');

      final mapped = mapExternalDeepLinkToRoute(uri);

      expect(mapped, isNull);
    });

    test('maps universal link with trusted host', () {
      final uri = Uri.parse(
        'https://nhinanchualanh.vn/payment/result?orderCode=123',
      );

      final mapped = mapExternalDeepLinkToRoute(uri);

      expect(mapped, '${RoutePaths.paymentResult}?orderCode=123');
    });

    test('ignores universal link from untrusted host', () {
      final uri = Uri.parse('https://example.com/payment/result?orderCode=123');

      final mapped = mapExternalDeepLinkToRoute(uri);

      expect(mapped, isNull);
    });

    test('returns null for non-deeplink uri', () {
      final uri = Uri.parse('/payment-result?orderId=abc');

      final mapped = mapExternalDeepLinkToRoute(uri);

      expect(mapped, isNull);
    });
  });
}
