// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'referral_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserReferralModel {

 String get referralCode; String? get discountCode; double? get discountPercent;
/// Create a copy of UserReferralModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserReferralModelCopyWith<UserReferralModel> get copyWith => _$UserReferralModelCopyWithImpl<UserReferralModel>(this as UserReferralModel, _$identity);

  /// Serializes this UserReferralModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserReferralModel&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,referralCode,discountCode,discountPercent);

@override
String toString() {
  return 'UserReferralModel(referralCode: $referralCode, discountCode: $discountCode, discountPercent: $discountPercent)';
}


}

/// @nodoc
abstract mixin class $UserReferralModelCopyWith<$Res>  {
  factory $UserReferralModelCopyWith(UserReferralModel value, $Res Function(UserReferralModel) _then) = _$UserReferralModelCopyWithImpl;
@useResult
$Res call({
 String referralCode, String? discountCode, double? discountPercent
});




}
/// @nodoc
class _$UserReferralModelCopyWithImpl<$Res>
    implements $UserReferralModelCopyWith<$Res> {
  _$UserReferralModelCopyWithImpl(this._self, this._then);

  final UserReferralModel _self;
  final $Res Function(UserReferralModel) _then;

/// Create a copy of UserReferralModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? referralCode = null,Object? discountCode = freezed,Object? discountPercent = freezed,}) {
  return _then(_self.copyWith(
referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,discountPercent: freezed == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserReferralModel].
extension UserReferralModelPatterns on UserReferralModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserReferralModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserReferralModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserReferralModel value)  $default,){
final _that = this;
switch (_that) {
case _UserReferralModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserReferralModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserReferralModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String referralCode,  String? discountCode,  double? discountPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserReferralModel() when $default != null:
return $default(_that.referralCode,_that.discountCode,_that.discountPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String referralCode,  String? discountCode,  double? discountPercent)  $default,) {final _that = this;
switch (_that) {
case _UserReferralModel():
return $default(_that.referralCode,_that.discountCode,_that.discountPercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String referralCode,  String? discountCode,  double? discountPercent)?  $default,) {final _that = this;
switch (_that) {
case _UserReferralModel() when $default != null:
return $default(_that.referralCode,_that.discountCode,_that.discountPercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserReferralModel implements UserReferralModel {
  const _UserReferralModel({required this.referralCode, this.discountCode, this.discountPercent});
  factory _UserReferralModel.fromJson(Map<String, dynamic> json) => _$UserReferralModelFromJson(json);

@override final  String referralCode;
@override final  String? discountCode;
@override final  double? discountPercent;

/// Create a copy of UserReferralModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserReferralModelCopyWith<_UserReferralModel> get copyWith => __$UserReferralModelCopyWithImpl<_UserReferralModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserReferralModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserReferralModel&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,referralCode,discountCode,discountPercent);

@override
String toString() {
  return 'UserReferralModel(referralCode: $referralCode, discountCode: $discountCode, discountPercent: $discountPercent)';
}


}

/// @nodoc
abstract mixin class _$UserReferralModelCopyWith<$Res> implements $UserReferralModelCopyWith<$Res> {
  factory _$UserReferralModelCopyWith(_UserReferralModel value, $Res Function(_UserReferralModel) _then) = __$UserReferralModelCopyWithImpl;
@override @useResult
$Res call({
 String referralCode, String? discountCode, double? discountPercent
});




}
/// @nodoc
class __$UserReferralModelCopyWithImpl<$Res>
    implements _$UserReferralModelCopyWith<$Res> {
  __$UserReferralModelCopyWithImpl(this._self, this._then);

  final _UserReferralModel _self;
  final $Res Function(_UserReferralModel) _then;

/// Create a copy of UserReferralModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? referralCode = null,Object? discountCode = freezed,Object? discountPercent = freezed,}) {
  return _then(_UserReferralModel(
referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,discountPercent: freezed == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
