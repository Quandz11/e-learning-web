// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckoutRequestModel {

 List<String> get courseIds; String? get wellnessPackageCode; String? get referralCode; String? get returnUrl; String? get cancelUrl;
/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutRequestModelCopyWith<CheckoutRequestModel> get copyWith => _$CheckoutRequestModelCopyWithImpl<CheckoutRequestModel>(this as CheckoutRequestModel, _$identity);

  /// Serializes this CheckoutRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutRequestModel&&const DeepCollectionEquality().equals(other.courseIds, courseIds)&&(identical(other.wellnessPackageCode, wellnessPackageCode) || other.wellnessPackageCode == wellnessPackageCode)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.returnUrl, returnUrl) || other.returnUrl == returnUrl)&&(identical(other.cancelUrl, cancelUrl) || other.cancelUrl == cancelUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(courseIds),wellnessPackageCode,referralCode,returnUrl,cancelUrl);

@override
String toString() {
  return 'CheckoutRequestModel(courseIds: $courseIds, wellnessPackageCode: $wellnessPackageCode, referralCode: $referralCode, returnUrl: $returnUrl, cancelUrl: $cancelUrl)';
}


}

/// @nodoc
abstract mixin class $CheckoutRequestModelCopyWith<$Res>  {
  factory $CheckoutRequestModelCopyWith(CheckoutRequestModel value, $Res Function(CheckoutRequestModel) _then) = _$CheckoutRequestModelCopyWithImpl;
@useResult
$Res call({
 List<String> courseIds, String? wellnessPackageCode, String? referralCode, String? returnUrl, String? cancelUrl
});




}
/// @nodoc
class _$CheckoutRequestModelCopyWithImpl<$Res>
    implements $CheckoutRequestModelCopyWith<$Res> {
  _$CheckoutRequestModelCopyWithImpl(this._self, this._then);

  final CheckoutRequestModel _self;
  final $Res Function(CheckoutRequestModel) _then;

/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseIds = null,Object? wellnessPackageCode = freezed,Object? referralCode = freezed,Object? returnUrl = freezed,Object? cancelUrl = freezed,}) {
  return _then(_self.copyWith(
courseIds: null == courseIds ? _self.courseIds : courseIds // ignore: cast_nullable_to_non_nullable
as List<String>,wellnessPackageCode: freezed == wellnessPackageCode ? _self.wellnessPackageCode : wellnessPackageCode // ignore: cast_nullable_to_non_nullable
as String?,referralCode: freezed == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String?,returnUrl: freezed == returnUrl ? _self.returnUrl : returnUrl // ignore: cast_nullable_to_non_nullable
as String?,cancelUrl: freezed == cancelUrl ? _self.cancelUrl : cancelUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutRequestModel].
extension CheckoutRequestModelPatterns on CheckoutRequestModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutRequestModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> courseIds,  String? wellnessPackageCode,  String? referralCode,  String? returnUrl,  String? cancelUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that.courseIds,_that.wellnessPackageCode,_that.referralCode,_that.returnUrl,_that.cancelUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> courseIds,  String? wellnessPackageCode,  String? referralCode,  String? returnUrl,  String? cancelUrl)  $default,) {final _that = this;
switch (_that) {
case _CheckoutRequestModel():
return $default(_that.courseIds,_that.wellnessPackageCode,_that.referralCode,_that.returnUrl,_that.cancelUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> courseIds,  String? wellnessPackageCode,  String? referralCode,  String? returnUrl,  String? cancelUrl)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that.courseIds,_that.wellnessPackageCode,_that.referralCode,_that.returnUrl,_that.cancelUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutRequestModel implements CheckoutRequestModel {
  const _CheckoutRequestModel({required final  List<String> courseIds, this.wellnessPackageCode, this.referralCode, this.returnUrl, this.cancelUrl}): _courseIds = courseIds;
  factory _CheckoutRequestModel.fromJson(Map<String, dynamic> json) => _$CheckoutRequestModelFromJson(json);

 final  List<String> _courseIds;
@override List<String> get courseIds {
  if (_courseIds is EqualUnmodifiableListView) return _courseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courseIds);
}

@override final  String? wellnessPackageCode;
@override final  String? referralCode;
@override final  String? returnUrl;
@override final  String? cancelUrl;

/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutRequestModelCopyWith<_CheckoutRequestModel> get copyWith => __$CheckoutRequestModelCopyWithImpl<_CheckoutRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutRequestModel&&const DeepCollectionEquality().equals(other._courseIds, _courseIds)&&(identical(other.wellnessPackageCode, wellnessPackageCode) || other.wellnessPackageCode == wellnessPackageCode)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.returnUrl, returnUrl) || other.returnUrl == returnUrl)&&(identical(other.cancelUrl, cancelUrl) || other.cancelUrl == cancelUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_courseIds),wellnessPackageCode,referralCode,returnUrl,cancelUrl);

@override
String toString() {
  return 'CheckoutRequestModel(courseIds: $courseIds, wellnessPackageCode: $wellnessPackageCode, referralCode: $referralCode, returnUrl: $returnUrl, cancelUrl: $cancelUrl)';
}


}

/// @nodoc
abstract mixin class _$CheckoutRequestModelCopyWith<$Res> implements $CheckoutRequestModelCopyWith<$Res> {
  factory _$CheckoutRequestModelCopyWith(_CheckoutRequestModel value, $Res Function(_CheckoutRequestModel) _then) = __$CheckoutRequestModelCopyWithImpl;
@override @useResult
$Res call({
 List<String> courseIds, String? wellnessPackageCode, String? referralCode, String? returnUrl, String? cancelUrl
});




}
/// @nodoc
class __$CheckoutRequestModelCopyWithImpl<$Res>
    implements _$CheckoutRequestModelCopyWith<$Res> {
  __$CheckoutRequestModelCopyWithImpl(this._self, this._then);

  final _CheckoutRequestModel _self;
  final $Res Function(_CheckoutRequestModel) _then;

/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseIds = null,Object? wellnessPackageCode = freezed,Object? referralCode = freezed,Object? returnUrl = freezed,Object? cancelUrl = freezed,}) {
  return _then(_CheckoutRequestModel(
courseIds: null == courseIds ? _self._courseIds : courseIds // ignore: cast_nullable_to_non_nullable
as List<String>,wellnessPackageCode: freezed == wellnessPackageCode ? _self.wellnessPackageCode : wellnessPackageCode // ignore: cast_nullable_to_non_nullable
as String?,referralCode: freezed == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String?,returnUrl: freezed == returnUrl ? _self.returnUrl : returnUrl // ignore: cast_nullable_to_non_nullable
as String?,cancelUrl: freezed == cancelUrl ? _self.cancelUrl : cancelUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CheckoutResponseModel {

 String get orderId; int? get payOSOrderCode; double get totalAmount; String get status; bool get requiresPayment; String? get checkoutUrl; String? get qrCode;
/// Create a copy of CheckoutResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutResponseModelCopyWith<CheckoutResponseModel> get copyWith => _$CheckoutResponseModelCopyWithImpl<CheckoutResponseModel>(this as CheckoutResponseModel, _$identity);

  /// Serializes this CheckoutResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutResponseModel&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.payOSOrderCode, payOSOrderCode) || other.payOSOrderCode == payOSOrderCode)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,payOSOrderCode,totalAmount,status,requiresPayment,checkoutUrl,qrCode);

@override
String toString() {
  return 'CheckoutResponseModel(orderId: $orderId, payOSOrderCode: $payOSOrderCode, totalAmount: $totalAmount, status: $status, requiresPayment: $requiresPayment, checkoutUrl: $checkoutUrl, qrCode: $qrCode)';
}


}

/// @nodoc
abstract mixin class $CheckoutResponseModelCopyWith<$Res>  {
  factory $CheckoutResponseModelCopyWith(CheckoutResponseModel value, $Res Function(CheckoutResponseModel) _then) = _$CheckoutResponseModelCopyWithImpl;
@useResult
$Res call({
 String orderId, int? payOSOrderCode, double totalAmount, String status, bool requiresPayment, String? checkoutUrl, String? qrCode
});




}
/// @nodoc
class _$CheckoutResponseModelCopyWithImpl<$Res>
    implements $CheckoutResponseModelCopyWith<$Res> {
  _$CheckoutResponseModelCopyWithImpl(this._self, this._then);

  final CheckoutResponseModel _self;
  final $Res Function(CheckoutResponseModel) _then;

/// Create a copy of CheckoutResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? payOSOrderCode = freezed,Object? totalAmount = null,Object? status = null,Object? requiresPayment = null,Object? checkoutUrl = freezed,Object? qrCode = freezed,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,payOSOrderCode: freezed == payOSOrderCode ? _self.payOSOrderCode : payOSOrderCode // ignore: cast_nullable_to_non_nullable
as int?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutResponseModel].
extension CheckoutResponseModelPatterns on CheckoutResponseModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutResponseModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutResponseModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutResponseModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  int? payOSOrderCode,  double totalAmount,  String status,  bool requiresPayment,  String? checkoutUrl,  String? qrCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutResponseModel() when $default != null:
return $default(_that.orderId,_that.payOSOrderCode,_that.totalAmount,_that.status,_that.requiresPayment,_that.checkoutUrl,_that.qrCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  int? payOSOrderCode,  double totalAmount,  String status,  bool requiresPayment,  String? checkoutUrl,  String? qrCode)  $default,) {final _that = this;
switch (_that) {
case _CheckoutResponseModel():
return $default(_that.orderId,_that.payOSOrderCode,_that.totalAmount,_that.status,_that.requiresPayment,_that.checkoutUrl,_that.qrCode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  int? payOSOrderCode,  double totalAmount,  String status,  bool requiresPayment,  String? checkoutUrl,  String? qrCode)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutResponseModel() when $default != null:
return $default(_that.orderId,_that.payOSOrderCode,_that.totalAmount,_that.status,_that.requiresPayment,_that.checkoutUrl,_that.qrCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutResponseModel implements CheckoutResponseModel {
  const _CheckoutResponseModel({required this.orderId, this.payOSOrderCode, required this.totalAmount, required this.status, required this.requiresPayment, this.checkoutUrl, this.qrCode});
  factory _CheckoutResponseModel.fromJson(Map<String, dynamic> json) => _$CheckoutResponseModelFromJson(json);

@override final  String orderId;
@override final  int? payOSOrderCode;
@override final  double totalAmount;
@override final  String status;
@override final  bool requiresPayment;
@override final  String? checkoutUrl;
@override final  String? qrCode;

/// Create a copy of CheckoutResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutResponseModelCopyWith<_CheckoutResponseModel> get copyWith => __$CheckoutResponseModelCopyWithImpl<_CheckoutResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutResponseModel&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.payOSOrderCode, payOSOrderCode) || other.payOSOrderCode == payOSOrderCode)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,payOSOrderCode,totalAmount,status,requiresPayment,checkoutUrl,qrCode);

@override
String toString() {
  return 'CheckoutResponseModel(orderId: $orderId, payOSOrderCode: $payOSOrderCode, totalAmount: $totalAmount, status: $status, requiresPayment: $requiresPayment, checkoutUrl: $checkoutUrl, qrCode: $qrCode)';
}


}

/// @nodoc
abstract mixin class _$CheckoutResponseModelCopyWith<$Res> implements $CheckoutResponseModelCopyWith<$Res> {
  factory _$CheckoutResponseModelCopyWith(_CheckoutResponseModel value, $Res Function(_CheckoutResponseModel) _then) = __$CheckoutResponseModelCopyWithImpl;
@override @useResult
$Res call({
 String orderId, int? payOSOrderCode, double totalAmount, String status, bool requiresPayment, String? checkoutUrl, String? qrCode
});




}
/// @nodoc
class __$CheckoutResponseModelCopyWithImpl<$Res>
    implements _$CheckoutResponseModelCopyWith<$Res> {
  __$CheckoutResponseModelCopyWithImpl(this._self, this._then);

  final _CheckoutResponseModel _self;
  final $Res Function(_CheckoutResponseModel) _then;

/// Create a copy of CheckoutResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? payOSOrderCode = freezed,Object? totalAmount = null,Object? status = null,Object? requiresPayment = null,Object? checkoutUrl = freezed,Object? qrCode = freezed,}) {
  return _then(_CheckoutResponseModel(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,payOSOrderCode: freezed == payOSOrderCode ? _self.payOSOrderCode : payOSOrderCode // ignore: cast_nullable_to_non_nullable
as int?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
