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

 String get id; String get title; String? get description; bool get isFree; double get price; List<LessonDto> get lessons;
/// Create a copy of CourseDetailModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseDetailModelCopyWith<CourseDetailModel> get copyWith => _$CourseDetailModelCopyWithImpl<CourseDetailModel>(this as CourseDetailModel, _$identity);

  /// Serializes this CourseDetailModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.price, price) || other.price == price)&&const DeepCollectionEquality().equals(other.lessons, lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,isFree,price,const DeepCollectionEquality().hash(lessons));

@override
String toString() {
  return 'CourseDetailModel(id: $id, title: $title, description: $description, isFree: $isFree, price: $price, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class $CourseDetailModelCopyWith<$Res>  {
  factory $CourseDetailModelCopyWith(CourseDetailModel value, $Res Function(CourseDetailModel) _then) = _$CourseDetailModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, bool isFree, double price, List<LessonDto> lessons
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? isFree = null,Object? price = null,Object? lessons = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<LessonDto>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  bool isFree,  double price,  List<LessonDto> lessons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseDetailModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.isFree,_that.price,_that.lessons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  bool isFree,  double price,  List<LessonDto> lessons)  $default,) {final _that = this;
switch (_that) {
case _CourseDetailModel():
return $default(_that.id,_that.title,_that.description,_that.isFree,_that.price,_that.lessons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  bool isFree,  double price,  List<LessonDto> lessons)?  $default,) {final _that = this;
switch (_that) {
case _CourseDetailModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.isFree,_that.price,_that.lessons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseDetailModel implements CourseDetailModel {
  const _CourseDetailModel({required this.id, required this.title, this.description, required this.isFree, required this.price, final  List<LessonDto> lessons = const []}): _lessons = lessons;
  factory _CourseDetailModel.fromJson(Map<String, dynamic> json) => _$CourseDetailModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override final  bool isFree;
@override final  double price;
 final  List<LessonDto> _lessons;
@override@JsonKey() List<LessonDto> get lessons {
  if (_lessons is EqualUnmodifiableListView) return _lessons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lessons);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.price, price) || other.price == price)&&const DeepCollectionEquality().equals(other._lessons, _lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,isFree,price,const DeepCollectionEquality().hash(_lessons));

@override
String toString() {
  return 'CourseDetailModel(id: $id, title: $title, description: $description, isFree: $isFree, price: $price, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class _$CourseDetailModelCopyWith<$Res> implements $CourseDetailModelCopyWith<$Res> {
  factory _$CourseDetailModelCopyWith(_CourseDetailModel value, $Res Function(_CourseDetailModel) _then) = __$CourseDetailModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, bool isFree, double price, List<LessonDto> lessons
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? isFree = null,Object? price = null,Object? lessons = null,}) {
  return _then(_CourseDetailModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,lessons: null == lessons ? _self._lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<LessonDto>,
  ));
}


}


/// @nodoc
mixin _$LessonDto {

 String get id; String get title; List<LessonPartDto> get parts;
/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonDtoCopyWith<LessonDto> get copyWith => _$LessonDtoCopyWithImpl<LessonDto>(this as LessonDto, _$identity);

  /// Serializes this LessonDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.parts, parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(parts));

@override
String toString() {
  return 'LessonDto(id: $id, title: $title, parts: $parts)';
}


}

/// @nodoc
abstract mixin class $LessonDtoCopyWith<$Res>  {
  factory $LessonDtoCopyWith(LessonDto value, $Res Function(LessonDto) _then) = _$LessonDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<LessonPartDto> parts
});




}
/// @nodoc
class _$LessonDtoCopyWithImpl<$Res>
    implements $LessonDtoCopyWith<$Res> {
  _$LessonDtoCopyWithImpl(this._self, this._then);

  final LessonDto _self;
  final $Res Function(LessonDto) _then;

/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? parts = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<LessonPartDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonDto].
extension LessonDtoPatterns on LessonDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonDto value)  $default,){
final _that = this;
switch (_that) {
case _LessonDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonDto value)?  $default,){
final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<LessonPartDto> parts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
return $default(_that.id,_that.title,_that.parts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<LessonPartDto> parts)  $default,) {final _that = this;
switch (_that) {
case _LessonDto():
return $default(_that.id,_that.title,_that.parts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<LessonPartDto> parts)?  $default,) {final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
return $default(_that.id,_that.title,_that.parts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonDto implements LessonDto {
  const _LessonDto({required this.id, required this.title, final  List<LessonPartDto> parts = const []}): _parts = parts;
  factory _LessonDto.fromJson(Map<String, dynamic> json) => _$LessonDtoFromJson(json);

@override final  String id;
@override final  String title;
 final  List<LessonPartDto> _parts;
@override@JsonKey() List<LessonPartDto> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}


/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonDtoCopyWith<_LessonDto> get copyWith => __$LessonDtoCopyWithImpl<_LessonDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._parts, _parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_parts));

@override
String toString() {
  return 'LessonDto(id: $id, title: $title, parts: $parts)';
}


}

/// @nodoc
abstract mixin class _$LessonDtoCopyWith<$Res> implements $LessonDtoCopyWith<$Res> {
  factory _$LessonDtoCopyWith(_LessonDto value, $Res Function(_LessonDto) _then) = __$LessonDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<LessonPartDto> parts
});




}
/// @nodoc
class __$LessonDtoCopyWithImpl<$Res>
    implements _$LessonDtoCopyWith<$Res> {
  __$LessonDtoCopyWithImpl(this._self, this._then);

  final _LessonDto _self;
  final $Res Function(_LessonDto) _then;

/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? parts = null,}) {
  return _then(_LessonDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<LessonPartDto>,
  ));
}


}


/// @nodoc
mixin _$LessonPartDto {

 String get id; String get title; String get type;// Video, Document
 String? get videoId; String? get documentUrl; int? get videoDuration;
/// Create a copy of LessonPartDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonPartDtoCopyWith<LessonPartDto> get copyWith => _$LessonPartDtoCopyWithImpl<LessonPartDto>(this as LessonPartDto, _$identity);

  /// Serializes this LessonPartDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonPartDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.documentUrl, documentUrl) || other.documentUrl == documentUrl)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,videoId,documentUrl,videoDuration);

@override
String toString() {
  return 'LessonPartDto(id: $id, title: $title, type: $type, videoId: $videoId, documentUrl: $documentUrl, videoDuration: $videoDuration)';
}


}

/// @nodoc
abstract mixin class $LessonPartDtoCopyWith<$Res>  {
  factory $LessonPartDtoCopyWith(LessonPartDto value, $Res Function(LessonPartDto) _then) = _$LessonPartDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String type, String? videoId, String? documentUrl, int? videoDuration
});




}
/// @nodoc
class _$LessonPartDtoCopyWithImpl<$Res>
    implements $LessonPartDtoCopyWith<$Res> {
  _$LessonPartDtoCopyWithImpl(this._self, this._then);

  final LessonPartDto _self;
  final $Res Function(LessonPartDto) _then;

/// Create a copy of LessonPartDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? type = null,Object? videoId = freezed,Object? documentUrl = freezed,Object? videoDuration = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,videoId: freezed == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String?,documentUrl: freezed == documentUrl ? _self.documentUrl : documentUrl // ignore: cast_nullable_to_non_nullable
as String?,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonPartDto].
extension LessonPartDtoPatterns on LessonPartDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonPartDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonPartDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonPartDto value)  $default,){
final _that = this;
switch (_that) {
case _LessonPartDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonPartDto value)?  $default,){
final _that = this;
switch (_that) {
case _LessonPartDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String type,  String? videoId,  String? documentUrl,  int? videoDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonPartDto() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.videoId,_that.documentUrl,_that.videoDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String type,  String? videoId,  String? documentUrl,  int? videoDuration)  $default,) {final _that = this;
switch (_that) {
case _LessonPartDto():
return $default(_that.id,_that.title,_that.type,_that.videoId,_that.documentUrl,_that.videoDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String type,  String? videoId,  String? documentUrl,  int? videoDuration)?  $default,) {final _that = this;
switch (_that) {
case _LessonPartDto() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.videoId,_that.documentUrl,_that.videoDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonPartDto implements LessonPartDto {
  const _LessonPartDto({required this.id, required this.title, required this.type, this.videoId, this.documentUrl, this.videoDuration});
  factory _LessonPartDto.fromJson(Map<String, dynamic> json) => _$LessonPartDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String type;
// Video, Document
@override final  String? videoId;
@override final  String? documentUrl;
@override final  int? videoDuration;

/// Create a copy of LessonPartDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonPartDtoCopyWith<_LessonPartDto> get copyWith => __$LessonPartDtoCopyWithImpl<_LessonPartDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonPartDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonPartDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.documentUrl, documentUrl) || other.documentUrl == documentUrl)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,videoId,documentUrl,videoDuration);

@override
String toString() {
  return 'LessonPartDto(id: $id, title: $title, type: $type, videoId: $videoId, documentUrl: $documentUrl, videoDuration: $videoDuration)';
}


}

/// @nodoc
abstract mixin class _$LessonPartDtoCopyWith<$Res> implements $LessonPartDtoCopyWith<$Res> {
  factory _$LessonPartDtoCopyWith(_LessonPartDto value, $Res Function(_LessonPartDto) _then) = __$LessonPartDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String type, String? videoId, String? documentUrl, int? videoDuration
});




}
/// @nodoc
class __$LessonPartDtoCopyWithImpl<$Res>
    implements _$LessonPartDtoCopyWith<$Res> {
  __$LessonPartDtoCopyWithImpl(this._self, this._then);

  final _LessonPartDto _self;
  final $Res Function(_LessonPartDto) _then;

/// Create a copy of LessonPartDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? type = null,Object? videoId = freezed,Object? documentUrl = freezed,Object? videoDuration = freezed,}) {
  return _then(_LessonPartDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,videoId: freezed == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String?,documentUrl: freezed == documentUrl ? _self.documentUrl : documentUrl // ignore: cast_nullable_to_non_nullable
as String?,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$EnrollmentProgressModel {

 String get enrollmentId; double get progressPercentage; int get completedParts; int get totalParts; List<LessonPartProgressModel> get partProgress;
/// Create a copy of EnrollmentProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrollmentProgressModelCopyWith<EnrollmentProgressModel> get copyWith => _$EnrollmentProgressModelCopyWithImpl<EnrollmentProgressModel>(this as EnrollmentProgressModel, _$identity);

  /// Serializes this EnrollmentProgressModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrollmentProgressModel&&(identical(other.enrollmentId, enrollmentId) || other.enrollmentId == enrollmentId)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.completedParts, completedParts) || other.completedParts == completedParts)&&(identical(other.totalParts, totalParts) || other.totalParts == totalParts)&&const DeepCollectionEquality().equals(other.partProgress, partProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollmentId,progressPercentage,completedParts,totalParts,const DeepCollectionEquality().hash(partProgress));

@override
String toString() {
  return 'EnrollmentProgressModel(enrollmentId: $enrollmentId, progressPercentage: $progressPercentage, completedParts: $completedParts, totalParts: $totalParts, partProgress: $partProgress)';
}


}

/// @nodoc
abstract mixin class $EnrollmentProgressModelCopyWith<$Res>  {
  factory $EnrollmentProgressModelCopyWith(EnrollmentProgressModel value, $Res Function(EnrollmentProgressModel) _then) = _$EnrollmentProgressModelCopyWithImpl;
@useResult
$Res call({
 String enrollmentId, double progressPercentage, int completedParts, int totalParts, List<LessonPartProgressModel> partProgress
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
@pragma('vm:prefer-inline') @override $Res call({Object? enrollmentId = null,Object? progressPercentage = null,Object? completedParts = null,Object? totalParts = null,Object? partProgress = null,}) {
  return _then(_self.copyWith(
enrollmentId: null == enrollmentId ? _self.enrollmentId : enrollmentId // ignore: cast_nullable_to_non_nullable
as String,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,completedParts: null == completedParts ? _self.completedParts : completedParts // ignore: cast_nullable_to_non_nullable
as int,totalParts: null == totalParts ? _self.totalParts : totalParts // ignore: cast_nullable_to_non_nullable
as int,partProgress: null == partProgress ? _self.partProgress : partProgress // ignore: cast_nullable_to_non_nullable
as List<LessonPartProgressModel>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String enrollmentId,  double progressPercentage,  int completedParts,  int totalParts,  List<LessonPartProgressModel> partProgress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrollmentProgressModel() when $default != null:
return $default(_that.enrollmentId,_that.progressPercentage,_that.completedParts,_that.totalParts,_that.partProgress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String enrollmentId,  double progressPercentage,  int completedParts,  int totalParts,  List<LessonPartProgressModel> partProgress)  $default,) {final _that = this;
switch (_that) {
case _EnrollmentProgressModel():
return $default(_that.enrollmentId,_that.progressPercentage,_that.completedParts,_that.totalParts,_that.partProgress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String enrollmentId,  double progressPercentage,  int completedParts,  int totalParts,  List<LessonPartProgressModel> partProgress)?  $default,) {final _that = this;
switch (_that) {
case _EnrollmentProgressModel() when $default != null:
return $default(_that.enrollmentId,_that.progressPercentage,_that.completedParts,_that.totalParts,_that.partProgress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrollmentProgressModel implements EnrollmentProgressModel {
  const _EnrollmentProgressModel({required this.enrollmentId, required this.progressPercentage, this.completedParts = 0, this.totalParts = 0, final  List<LessonPartProgressModel> partProgress = const []}): _partProgress = partProgress;
  factory _EnrollmentProgressModel.fromJson(Map<String, dynamic> json) => _$EnrollmentProgressModelFromJson(json);

@override final  String enrollmentId;
@override final  double progressPercentage;
@override@JsonKey() final  int completedParts;
@override@JsonKey() final  int totalParts;
 final  List<LessonPartProgressModel> _partProgress;
@override@JsonKey() List<LessonPartProgressModel> get partProgress {
  if (_partProgress is EqualUnmodifiableListView) return _partProgress;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_partProgress);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollmentProgressModel&&(identical(other.enrollmentId, enrollmentId) || other.enrollmentId == enrollmentId)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.completedParts, completedParts) || other.completedParts == completedParts)&&(identical(other.totalParts, totalParts) || other.totalParts == totalParts)&&const DeepCollectionEquality().equals(other._partProgress, _partProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollmentId,progressPercentage,completedParts,totalParts,const DeepCollectionEquality().hash(_partProgress));

@override
String toString() {
  return 'EnrollmentProgressModel(enrollmentId: $enrollmentId, progressPercentage: $progressPercentage, completedParts: $completedParts, totalParts: $totalParts, partProgress: $partProgress)';
}


}

/// @nodoc
abstract mixin class _$EnrollmentProgressModelCopyWith<$Res> implements $EnrollmentProgressModelCopyWith<$Res> {
  factory _$EnrollmentProgressModelCopyWith(_EnrollmentProgressModel value, $Res Function(_EnrollmentProgressModel) _then) = __$EnrollmentProgressModelCopyWithImpl;
@override @useResult
$Res call({
 String enrollmentId, double progressPercentage, int completedParts, int totalParts, List<LessonPartProgressModel> partProgress
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
@override @pragma('vm:prefer-inline') $Res call({Object? enrollmentId = null,Object? progressPercentage = null,Object? completedParts = null,Object? totalParts = null,Object? partProgress = null,}) {
  return _then(_EnrollmentProgressModel(
enrollmentId: null == enrollmentId ? _self.enrollmentId : enrollmentId // ignore: cast_nullable_to_non_nullable
as String,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,completedParts: null == completedParts ? _self.completedParts : completedParts // ignore: cast_nullable_to_non_nullable
as int,totalParts: null == totalParts ? _self.totalParts : totalParts // ignore: cast_nullable_to_non_nullable
as int,partProgress: null == partProgress ? _self._partProgress : partProgress // ignore: cast_nullable_to_non_nullable
as List<LessonPartProgressModel>,
  ));
}


}


/// @nodoc
mixin _$LessonPartProgressModel {

 String get lessonPartId; String get lessonPartTitle; bool get isCompleted; int get watchedDuration;
/// Create a copy of LessonPartProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonPartProgressModelCopyWith<LessonPartProgressModel> get copyWith => _$LessonPartProgressModelCopyWithImpl<LessonPartProgressModel>(this as LessonPartProgressModel, _$identity);

  /// Serializes this LessonPartProgressModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonPartProgressModel&&(identical(other.lessonPartId, lessonPartId) || other.lessonPartId == lessonPartId)&&(identical(other.lessonPartTitle, lessonPartTitle) || other.lessonPartTitle == lessonPartTitle)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.watchedDuration, watchedDuration) || other.watchedDuration == watchedDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonPartId,lessonPartTitle,isCompleted,watchedDuration);

@override
String toString() {
  return 'LessonPartProgressModel(lessonPartId: $lessonPartId, lessonPartTitle: $lessonPartTitle, isCompleted: $isCompleted, watchedDuration: $watchedDuration)';
}


}

/// @nodoc
abstract mixin class $LessonPartProgressModelCopyWith<$Res>  {
  factory $LessonPartProgressModelCopyWith(LessonPartProgressModel value, $Res Function(LessonPartProgressModel) _then) = _$LessonPartProgressModelCopyWithImpl;
@useResult
$Res call({
 String lessonPartId, String lessonPartTitle, bool isCompleted, int watchedDuration
});




}
/// @nodoc
class _$LessonPartProgressModelCopyWithImpl<$Res>
    implements $LessonPartProgressModelCopyWith<$Res> {
  _$LessonPartProgressModelCopyWithImpl(this._self, this._then);

  final LessonPartProgressModel _self;
  final $Res Function(LessonPartProgressModel) _then;

/// Create a copy of LessonPartProgressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lessonPartId = null,Object? lessonPartTitle = null,Object? isCompleted = null,Object? watchedDuration = null,}) {
  return _then(_self.copyWith(
lessonPartId: null == lessonPartId ? _self.lessonPartId : lessonPartId // ignore: cast_nullable_to_non_nullable
as String,lessonPartTitle: null == lessonPartTitle ? _self.lessonPartTitle : lessonPartTitle // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,watchedDuration: null == watchedDuration ? _self.watchedDuration : watchedDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonPartProgressModel].
extension LessonPartProgressModelPatterns on LessonPartProgressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonPartProgressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonPartProgressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonPartProgressModel value)  $default,){
final _that = this;
switch (_that) {
case _LessonPartProgressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonPartProgressModel value)?  $default,){
final _that = this;
switch (_that) {
case _LessonPartProgressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String lessonPartId,  String lessonPartTitle,  bool isCompleted,  int watchedDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonPartProgressModel() when $default != null:
return $default(_that.lessonPartId,_that.lessonPartTitle,_that.isCompleted,_that.watchedDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String lessonPartId,  String lessonPartTitle,  bool isCompleted,  int watchedDuration)  $default,) {final _that = this;
switch (_that) {
case _LessonPartProgressModel():
return $default(_that.lessonPartId,_that.lessonPartTitle,_that.isCompleted,_that.watchedDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String lessonPartId,  String lessonPartTitle,  bool isCompleted,  int watchedDuration)?  $default,) {final _that = this;
switch (_that) {
case _LessonPartProgressModel() when $default != null:
return $default(_that.lessonPartId,_that.lessonPartTitle,_that.isCompleted,_that.watchedDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonPartProgressModel implements LessonPartProgressModel {
  const _LessonPartProgressModel({required this.lessonPartId, this.lessonPartTitle = '', this.isCompleted = false, this.watchedDuration = 0});
  factory _LessonPartProgressModel.fromJson(Map<String, dynamic> json) => _$LessonPartProgressModelFromJson(json);

@override final  String lessonPartId;
@override@JsonKey() final  String lessonPartTitle;
@override@JsonKey() final  bool isCompleted;
@override@JsonKey() final  int watchedDuration;

/// Create a copy of LessonPartProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonPartProgressModelCopyWith<_LessonPartProgressModel> get copyWith => __$LessonPartProgressModelCopyWithImpl<_LessonPartProgressModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonPartProgressModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonPartProgressModel&&(identical(other.lessonPartId, lessonPartId) || other.lessonPartId == lessonPartId)&&(identical(other.lessonPartTitle, lessonPartTitle) || other.lessonPartTitle == lessonPartTitle)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.watchedDuration, watchedDuration) || other.watchedDuration == watchedDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonPartId,lessonPartTitle,isCompleted,watchedDuration);

@override
String toString() {
  return 'LessonPartProgressModel(lessonPartId: $lessonPartId, lessonPartTitle: $lessonPartTitle, isCompleted: $isCompleted, watchedDuration: $watchedDuration)';
}


}

/// @nodoc
abstract mixin class _$LessonPartProgressModelCopyWith<$Res> implements $LessonPartProgressModelCopyWith<$Res> {
  factory _$LessonPartProgressModelCopyWith(_LessonPartProgressModel value, $Res Function(_LessonPartProgressModel) _then) = __$LessonPartProgressModelCopyWithImpl;
@override @useResult
$Res call({
 String lessonPartId, String lessonPartTitle, bool isCompleted, int watchedDuration
});




}
/// @nodoc
class __$LessonPartProgressModelCopyWithImpl<$Res>
    implements _$LessonPartProgressModelCopyWith<$Res> {
  __$LessonPartProgressModelCopyWithImpl(this._self, this._then);

  final _LessonPartProgressModel _self;
  final $Res Function(_LessonPartProgressModel) _then;

/// Create a copy of LessonPartProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lessonPartId = null,Object? lessonPartTitle = null,Object? isCompleted = null,Object? watchedDuration = null,}) {
  return _then(_LessonPartProgressModel(
lessonPartId: null == lessonPartId ? _self.lessonPartId : lessonPartId // ignore: cast_nullable_to_non_nullable
as String,lessonPartTitle: null == lessonPartTitle ? _self.lessonPartTitle : lessonPartTitle // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,watchedDuration: null == watchedDuration ? _self.watchedDuration : watchedDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
