// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserReferralModel _$UserReferralModelFromJson(Map<String, dynamic> json) =>
    _UserReferralModel(
      referralCode: json['referralCode'] as String,
      discountCode: json['discountCode'] as String?,
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UserReferralModelToJson(_UserReferralModel instance) =>
    <String, dynamic>{
      'referralCode': instance.referralCode,
      'discountCode': instance.discountCode,
      'discountPercent': instance.discountPercent,
    };
