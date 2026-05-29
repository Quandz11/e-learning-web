// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckoutRequestModel _$CheckoutRequestModelFromJson(
  Map<String, dynamic> json,
) => _CheckoutRequestModel(
  courseIds: (json['courseIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  wellnessPackageCode: json['wellnessPackageCode'] as String?,
  referralCode: json['referralCode'] as String?,
  returnUrl: json['returnUrl'] as String?,
  cancelUrl: json['cancelUrl'] as String?,
);

Map<String, dynamic> _$CheckoutRequestModelToJson(
  _CheckoutRequestModel instance,
) => <String, dynamic>{
  'courseIds': instance.courseIds,
  'wellnessPackageCode': instance.wellnessPackageCode,
  'referralCode': instance.referralCode,
  'returnUrl': instance.returnUrl,
  'cancelUrl': instance.cancelUrl,
};

_CheckoutResponseModel _$CheckoutResponseModelFromJson(
  Map<String, dynamic> json,
) => _CheckoutResponseModel(
  orderId: json['orderId'] as String,
  payOSOrderCode: (json['payOSOrderCode'] as num?)?.toInt(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  status: json['status'] as String,
  requiresPayment: json['requiresPayment'] as bool,
  checkoutUrl: json['checkoutUrl'] as String?,
  qrCode: json['qrCode'] as String?,
);

Map<String, dynamic> _$CheckoutResponseModelToJson(
  _CheckoutResponseModel instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'payOSOrderCode': instance.payOSOrderCode,
  'totalAmount': instance.totalAmount,
  'status': instance.status,
  'requiresPayment': instance.requiresPayment,
  'checkoutUrl': instance.checkoutUrl,
  'qrCode': instance.qrCode,
};
