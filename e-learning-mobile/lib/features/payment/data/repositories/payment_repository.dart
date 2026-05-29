import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../models/payment_models.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(apiClientProvider));
});

class PaymentRepository {
  PaymentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> previewReferral(String code) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/payments/referrals/preview',
      queryParameters: {'code': code},
    );
  }

  Future<CheckoutResponseModel> createCheckout(
    CheckoutRequestModel request,
  ) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/payments/checkout',
      data: request.toJson(),
    );
    return CheckoutResponseModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final data = await _apiClient.get<List<dynamic>>('/payments/orders');
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> getOrderStatus(
    String orderId, {
    bool refresh = true,
  }) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/payments/orders/$orderId',
      queryParameters: {'refresh': refresh},
    );
  }

  Future<Map<String, dynamic>> getOrderStatusByCode(
    int code, {
    bool refresh = true,
  }) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/payments/orders/by-code/$code',
      queryParameters: {'refresh': refresh},
    );
  }
}
