import 'package:freezed_annotation/freezed_annotation.dart';

part 'referral_models.freezed.dart';
part 'referral_models.g.dart';

@freezed
abstract class UserReferralModel with _$UserReferralModel {
  const factory UserReferralModel({
    required String referralCode,
    String? discountCode,
    double? discountPercent,
  }) = _UserReferralModel;

  factory UserReferralModel.fromJson(Map<String, dynamic> json) =>
      _$UserReferralModelFromJson(json);
}
