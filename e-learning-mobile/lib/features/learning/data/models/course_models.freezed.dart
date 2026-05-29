// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourseSummaryModel {

 String get id; String get title; String? get thumbnailUrl; bool get isFree; double get price;
/// Create a copy of CourseSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseSummaryModelCopyWith<CourseSummaryModel> get copyWith => _$CourseSummaryModelCopyWithImpl<CourseSummaryModel>(this as CourseSummaryModel, _$identity);

  /// Serializes this CourseSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,thumbnailUrl,isFree,price);

@override
String toString() {
  return 'CourseSummaryModel(id: $id, title: $title, thumbnailUrl: $thumbnailUrl, isFree: $isFree, price: $price)';
}


}

/// @nodoc
abstract mixin class $CourseSummaryModelCopyWith<$Res>  {
  factory $CourseSummaryModelCopyWith(CourseSummaryModel value, $Res Function(CourseSummaryModel) _then) = _$CourseSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? thumbnailUrl, bool isFree, double price
});




}
/// @nodoc
class _$CourseSummaryModelCopyWithImpl<$Res>
    implements $CourseSummaryModelCopyWith<$Res> {
  _$CourseSummaryModelCopyWithImpl(this._self, this._then);

  final CourseSummaryModel _self;
  final $Res Function(CourseSummaryModel) _then;

/// Create a copy of CourseSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? thumbnailUrl = freezed,Object? isFree = null,Object? price = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseSummaryModel].
extension CourseSummaryModelPatterns on CourseSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _CourseSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _CourseSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? thumbnailUrl,  bool isFree,  double price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseSummaryModel() when $default != null:
return $default(_that.id,_that.title,_that.thumbnailUrl,_that.isFree,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? thumbnailUrl,  bool isFree,  double price)  $default,) {final _that = this;
switch (_that) {
case _CourseSummaryModel():
return $default(_that.id,_that.title,_that.thumbnailUrl,_that.isFree,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? thumbnailUrl,  bool isFree,  double price)?  $default,) {final _that = this;
switch (_that) {
case _CourseSummaryModel() when $default != null:
return $default(_that.id,_that.title,_that.thumbnailUrl,_that.isFree,_that.price);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseSummaryModel implements CourseSummaryModel {
  const _CourseSummaryModel({required this.id, required this.title, this.thumbnailUrl, required this.isFree, required this.price});
  factory _CourseSummaryModel.fromJson(Map<String, dynamic> json) => _$CourseSummaryModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? thumbnailUrl;
@override final  bool isFree;
@override final  double price;

/// Create a copy of CourseSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseSummaryModelCopyWith<_CourseSummaryModel> get copyWith => __$CourseSummaryModelCopyWithImpl<_CourseSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,thumbnailUrl,isFree,price);

@override
String toString() {
  return 'CourseSummaryModel(id: $id, title: $title, thumbnailUrl: $thumbnailUrl, isFree: $isFree, price: $price)';
}


}

/// @nodoc
abstract mixin class _$CourseSummaryModelCopyWith<$Res> implements $CourseSummaryModelCopyWith<$Res> {
  factory _$CourseSummaryModelCopyWith(_CourseSummaryModel value, $Res Function(_CourseSummaryModel) _then) = __$CourseSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? thumbnailUrl, bool isFree, double price
});




}
/// @nodoc
class __$CourseSummaryModelCopyWithImpl<$Res>
    implements _$CourseSummaryModelCopyWith<$Res> {
  __$CourseSummaryModelCopyWithImpl(this._self, this._then);

  final _CourseSummaryModel _self;
  final $Res Function(_CourseSummaryModel) _then;

/// Create a copy of CourseSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? thumbnailUrl = freezed,Object? isFree = null,Object? price = null,}) {
  return _then(_CourseSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$CourseDetailModel {

 String get id; String get title; String? get description; bool get isFree; double get price;
/// Create a copy of CourseDetailModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseDetailModelCopyWith<CourseDetailModel> get copyWith => _$CourseDetailModelCopyWithImpl<CourseDetailModel>(this as CourseDetailModel, _$identity);

  /// Serializes this CourseDetailModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,isFree,price);

@override
String toString() {
  return 'CourseDetailModel(id: $id, title: $title, description: $description, isFree: $isFree, price: $price)';
}


}

/// @nodoc
abstract mixin class $CourseDetailModelCopyWith<$Res>  {
  factory $CourseDetailModelCopyWith(CourseDetailModel value, $Res Function(CourseDetailModel) _then) = _$CourseDetailModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, bool isFree, double price
});




}
/// @nodoc
class _$CourseDetailModelCopyWithImpl<$Res>
    implements $CourseDetailModelCopyWith<$Res> {
  _$CourseDetailModelCopyWithImpl(this._self, this._then);

  final CourseDetailModel _self;
  final $Res Function(CourseDetailModel) _then;

/// Create a copy of CourseDetailModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? isFree = null,Object? price = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseDetailModel].
extension CourseDetailModelPatterns on CourseDetailModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseDetailModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseDetailModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseDetailModel value)  $default,){
final _that = this;
switch (_that) {
case _CourseDetailModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseDetailModel value)?  $default,){
final _that = this;
switch (_that) {
case _CourseDetailModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  bool isFree,  double price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseDetailModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.isFree,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  bool isFree,  double price)  $default,) {final _that = this;
switch (_that) {
case _CourseDetailModel():
return $default(_that.id,_that.title,_that.description,_that.isFree,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  bool isFree,  double price)?  $default,) {final _that = this;
switch (_that) {
case _CourseDetailModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.isFree,_that.price);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseDetailModel implements CourseDetailModel {
  const _CourseDetailModel({required this.id, required this.title, this.description, required this.isFree, required this.price});
  factory _CourseDetailModel.fromJson(Map<String, dynamic> json) => _$CourseDetailModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override final  bool isFree;
@override final  double price;

/// Create a copy of CourseDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseDetailModelCopyWith<_CourseDetailModel> get copyWith => __$CourseDetailModelCopyWithImpl<_CourseDetailModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseDetailModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,isFree,price);

@override
String toString() {
  return 'CourseDetailModel(id: $id, title: $title, description: $description, isFree: $isFree, price: $price)';
}


}

/// @nodoc
abstract mixin class _$CourseDetailModelCopyWith<$Res> implements $CourseDetailModelCopyWith<$Res> {
  factory _$CourseDetailModelCopyWith(_CourseDetailModel value, $Res Function(_CourseDetailModel) _then) = __$CourseDetailModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, bool isFree, double price
});




}
/// @nodoc
class __$CourseDetailModelCopyWithImpl<$Res>
    implements _$CourseDetailModelCopyWith<$Res> {
  __$CourseDetailModelCopyWithImpl(this._self, this._then);

  final _CourseDetailModel _self;
  final $Res Function(_CourseDetailModel) _then;

/// Create a copy of CourseDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? isFree = null,Object? price = null,}) {
  return _then(_CourseDetailModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$EnrollmentProgressModel {

 String get enrollmentId; double get progressPercentage;
/// Create a copy of EnrollmentProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrollmentProgressModelCopyWith<EnrollmentProgressModel> get copyWith => _$EnrollmentProgressModelCopyWithImpl<EnrollmentProgressModel>(this as EnrollmentProgressModel, _$identity);

  /// Serializes this EnrollmentProgressModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrollmentProgressModel&&(identical(other.enrollmentId, enrollmentId) || other.enrollmentId == enrollmentId)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollmentId,progressPercentage);

@override
String toString() {
  return 'EnrollmentProgressModel(enrollmentId: $enrollmentId, progressPercentage: $progressPercentage)';
}


}

/// @nodoc
abstract mixin class $EnrollmentProgressModelCopyWith<$Res>  {
  factory $EnrollmentProgressModelCopyWith(EnrollmentProgressModel value, $Res Function(EnrollmentProgressModel) _then) = _$EnrollmentProgressModelCopyWithImpl;
@useResult
$Res call({
 String enrollmentId, double progressPercentage
});




}
/// @nodoc
class _$EnrollmentProgressModelCopyWithImpl<$Res>
    implements $EnrollmentProgressModelCopyWith<$Res> {
  _$EnrollmentProgressModelCopyWithImpl(this._self, this._then);

  final EnrollmentProgressModel _self;
  final $Res Function(EnrollmentProgressModel) _then;

/// Create a copy of EnrollmentProgressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrollmentId = null,Object? progressPercentage = null,}) {
  return _then(_self.copyWith(
enrollmentId: null == enrollmentId ? _self.enrollmentId : enrollmentId // ignore: cast_nullable_to_non_nullable
as String,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [EnrollmentProgressModel].
extension EnrollmentProgressModelPatterns on EnrollmentProgressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrollmentProgressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrollmentProgressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrollmentProgressModel value)  $default,){
final _that = this;
switch (_that) {
case _EnrollmentProgressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrollmentProgressModel value)?  $default,){
final _that = this;
switch (_that) {
case _EnrollmentProgressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String enrollmentId,  double progressPercentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrollmentProgressModel() when $default != null:
return $default(_that.enrollmentId,_that.progressPercentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String enrollmentId,  double progressPercentage)  $default,) {final _that = this;
switch (_that) {
case _EnrollmentProgressModel():
return $default(_that.enrollmentId,_that.progressPercentage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String enrollmentId,  double progressPercentage)?  $default,) {final _that = this;
switch (_that) {
case _EnrollmentProgressModel() when $default != null:
return $default(_that.enrollmentId,_that.progressPercentage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrollmentProgressModel implements EnrollmentProgressModel {
  const _EnrollmentProgressModel({required this.enrollmentId, required this.progressPercentage});
  factory _EnrollmentProgressModel.fromJson(Map<String, dynamic> json) => _$EnrollmentProgressModelFromJson(json);

@override final  String enrollmentId;
@override final  double progressPercentage;

/// Create a copy of EnrollmentProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollmentProgressModelCopyWith<_EnrollmentProgressModel> get copyWith => __$EnrollmentProgressModelCopyWithImpl<_EnrollmentProgressModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrollmentProgressModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollmentProgressModel&&(identical(other.enrollmentId, enrollmentId) || other.enrollmentId == enrollmentId)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollmentId,progressPercentage);

@override
String toString() {
  return 'EnrollmentProgressModel(enrollmentId: $enrollmentId, progressPercentage: $progressPercentage)';
}


}

/// @nodoc
abstract mixin class _$EnrollmentProgressModelCopyWith<$Res> implements $EnrollmentProgressModelCopyWith<$Res> {
  factory _$EnrollmentProgressModelCopyWith(_EnrollmentProgressModel value, $Res Function(_EnrollmentProgressModel) _then) = __$EnrollmentProgressModelCopyWithImpl;
@override @useResult
$Res call({
 String enrollmentId, double progressPercentage
});




}
/// @nodoc
class __$EnrollmentProgressModelCopyWithImpl<$Res>
    implements _$EnrollmentProgressModelCopyWith<$Res> {
  __$EnrollmentProgressModelCopyWithImpl(this._self, this._then);

  final _EnrollmentProgressModel _self;
  final $Res Function(_EnrollmentProgressModel) _then;

/// Create a copy of EnrollmentProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrollmentId = null,Object? progressPercentage = null,}) {
  return _then(_EnrollmentProgressModel(
enrollmentId: null == enrollmentId ? _self.enrollmentId : enrollmentId // ignore: cast_nullable_to_non_nullable
as String,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
