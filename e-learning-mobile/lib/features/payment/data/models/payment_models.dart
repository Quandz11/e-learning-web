import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_models.freezed.dart';
part 'payment_models.g.dart';

@freezed
abstract class CheckoutRequestModel with _$CheckoutRequestModel {
  const factory CheckoutRequestModel({
    required List<String> courseIds,
    String? wellnessPackageCode,
    String? referralCode,
    String? returnUrl,
    String? cancelUrl,
  }) = _CheckoutRequestModel;

  factory CheckoutRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CheckoutRequestModelFromJson(json);
}

@freezed
abstract class CheckoutResponseModel with _$CheckoutResponseModel {
  const factory CheckoutResponseModel({
    required String orderId,
    int? payOSOrderCode,
    required double totalAmount,
    required String status,
    required bool requiresPayment,
    String? checkoutUrl,
    String? qrCode,
  }) = _CheckoutResponseModel;

  factory CheckoutResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CheckoutResponseModelFromJson(json);
}
