// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourseSummaryModel _$CourseSummaryModelFromJson(Map<String, dynamic> json) =>
    _CourseSummaryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isFree: json['isFree'] as bool,
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$CourseSummaryModelToJson(_CourseSummaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'thumbnailUrl': instance.thumbnailUrl,
      'isFree': instance.isFree,
      'price': instance.price,
    };

_CourseDetailModel _$CourseDetailModelFromJson(Map<String, dynamic> json) =>
    _CourseDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isFree: json['isFree'] as bool,
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$CourseDetailModelToJson(_CourseDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'isFree': instance.isFree,
      'price': instance.price,
    };

_EnrollmentProgressModel _$EnrollmentProgressModelFromJson(
  Map<String, dynamic> json,
) => _EnrollmentProgressModel(
  enrollmentId: json['enrollmentId'] as String,
  progressPercentage: (json['progressPercentage'] as num).toDouble(),
);

Map<String, dynamic> _$EnrollmentProgressModelToJson(
  _EnrollmentProgressModel instance,
) => <String, dynamic>{
  'enrollmentId': instance.enrollmentId,
  'progressPercentage': instance.progressPercentage,
};
