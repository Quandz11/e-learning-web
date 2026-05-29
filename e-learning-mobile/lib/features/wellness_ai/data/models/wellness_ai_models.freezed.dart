// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wellness_ai_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiStatusModel {

 bool get isEnabled; Map<String, dynamic>? get access;
/// Create a copy of AiStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiStatusModelCopyWith<AiStatusModel> get copyWith => _$AiStatusModelCopyWithImpl<AiStatusModel>(this as AiStatusModel, _$identity);

  /// Serializes this AiStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiStatusModel&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&const DeepCollectionEquality().equals(other.access, access));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isEnabled,const DeepCollectionEquality().hash(access));

@override
String toString() {
  return 'AiStatusModel(isEnabled: $isEnabled, access: $access)';
}


}

/// @nodoc
abstract mixin class $AiStatusModelCopyWith<$Res>  {
  factory $AiStatusModelCopyWith(AiStatusModel value, $Res Function(AiStatusModel) _then) = _$AiStatusModelCopyWithImpl;
@useResult
$Res call({
 bool isEnabled, Map<String, dynamic>? access
});




}
/// @nodoc
class _$AiStatusModelCopyWithImpl<$Res>
    implements $AiStatusModelCopyWith<$Res> {
  _$AiStatusModelCopyWithImpl(this._self, this._then);

  final AiStatusModel _self;
  final $Res Function(AiStatusModel) _then;

/// Create a copy of AiStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isEnabled = null,Object? access = freezed,}) {
  return _then(_self.copyWith(
isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,access: freezed == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiStatusModel].
extension AiStatusModelPatterns on AiStatusModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiStatusModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _AiStatusModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _AiStatusModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isEnabled,  Map<String, dynamic>? access)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiStatusModel() when $default != null:
return $default(_that.isEnabled,_that.access);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isEnabled,  Map<String, dynamic>? access)  $default,) {final _that = this;
switch (_that) {
case _AiStatusModel():
return $default(_that.isEnabled,_that.access);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isEnabled,  Map<String, dynamic>? access)?  $default,) {final _that = this;
switch (_that) {
case _AiStatusModel() when $default != null:
return $default(_that.isEnabled,_that.access);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiStatusModel implements AiStatusModel {
  const _AiStatusModel({required this.isEnabled, final  Map<String, dynamic>? access}): _access = access;
  factory _AiStatusModel.fromJson(Map<String, dynamic> json) => _$AiStatusModelFromJson(json);

@override final  bool isEnabled;
 final  Map<String, dynamic>? _access;
@override Map<String, dynamic>? get access {
  final value = _access;
  if (value == null) return null;
  if (_access is EqualUnmodifiableMapView) return _access;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AiStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiStatusModelCopyWith<_AiStatusModel> get copyWith => __$AiStatusModelCopyWithImpl<_AiStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiStatusModel&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&const DeepCollectionEquality().equals(other._access, _access));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isEnabled,const DeepCollectionEquality().hash(_access));

@override
String toString() {
  return 'AiStatusModel(isEnabled: $isEnabled, access: $access)';
}


}

/// @nodoc
abstract mixin class _$AiStatusModelCopyWith<$Res> implements $AiStatusModelCopyWith<$Res> {
  factory _$AiStatusModelCopyWith(_AiStatusModel value, $Res Function(_AiStatusModel) _then) = __$AiStatusModelCopyWithImpl;
@override @useResult
$Res call({
 bool isEnabled, Map<String, dynamic>? access
});




}
/// @nodoc
class __$AiStatusModelCopyWithImpl<$Res>
    implements _$AiStatusModelCopyWith<$Res> {
  __$AiStatusModelCopyWithImpl(this._self, this._then);

  final _AiStatusModel _self;
  final $Res Function(_AiStatusModel) _then;

/// Create a copy of AiStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isEnabled = null,Object? access = freezed,}) {
  return _then(_AiStatusModel(
isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,access: freezed == access ? _self._access : access // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
