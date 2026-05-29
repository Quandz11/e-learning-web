// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forum_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ForumCategoryModel {

 String get id; String get name; String? get description;
/// Create a copy of ForumCategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForumCategoryModelCopyWith<ForumCategoryModel> get copyWith => _$ForumCategoryModelCopyWithImpl<ForumCategoryModel>(this as ForumCategoryModel, _$identity);

  /// Serializes this ForumCategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'ForumCategoryModel(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $ForumCategoryModelCopyWith<$Res>  {
  factory $ForumCategoryModelCopyWith(ForumCategoryModel value, $Res Function(ForumCategoryModel) _then) = _$ForumCategoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description
});




}
/// @nodoc
class _$ForumCategoryModelCopyWithImpl<$Res>
    implements $ForumCategoryModelCopyWith<$Res> {
  _$ForumCategoryModelCopyWithImpl(this._self, this._then);

  final ForumCategoryModel _self;
  final $Res Function(ForumCategoryModel) _then;

/// Create a copy of ForumCategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ForumCategoryModel].
extension ForumCategoryModelPatterns on ForumCategoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ForumCategoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ForumCategoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ForumCategoryModel value)  $default,){
final _that = this;
switch (_that) {
case _ForumCategoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ForumCategoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _ForumCategoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ForumCategoryModel() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description)  $default,) {final _that = this;
switch (_that) {
case _ForumCategoryModel():
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _ForumCategoryModel() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ForumCategoryModel implements ForumCategoryModel {
  const _ForumCategoryModel({required this.id, required this.name, this.description});
  factory _ForumCategoryModel.fromJson(Map<String, dynamic> json) => _$ForumCategoryModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;

/// Create a copy of ForumCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForumCategoryModelCopyWith<_ForumCategoryModel> get copyWith => __$ForumCategoryModelCopyWithImpl<_ForumCategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ForumCategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForumCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'ForumCategoryModel(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ForumCategoryModelCopyWith<$Res> implements $ForumCategoryModelCopyWith<$Res> {
  factory _$ForumCategoryModelCopyWith(_ForumCategoryModel value, $Res Function(_ForumCategoryModel) _then) = __$ForumCategoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description
});




}
/// @nodoc
class __$ForumCategoryModelCopyWithImpl<$Res>
    implements _$ForumCategoryModelCopyWith<$Res> {
  __$ForumCategoryModelCopyWithImpl(this._self, this._then);

  final _ForumCategoryModel _self;
  final $Res Function(_ForumCategoryModel) _then;

/// Create a copy of ForumCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,}) {
  return _then(_ForumCategoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
