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
      lessons:
          (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CourseDetailModelToJson(_CourseDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'isFree': instance.isFree,
      'price': instance.price,
      'lessons': instance.lessons,
    };

_LessonDto _$LessonDtoFromJson(Map<String, dynamic> json) => _LessonDto(
  id: json['id'] as String,
  title: json['title'] as String,
  parts:
      (json['parts'] as List<dynamic>?)
          ?.map((e) => LessonPartDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LessonDtoToJson(_LessonDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'parts': instance.parts,
    };

_LessonPartDto _$LessonPartDtoFromJson(Map<String, dynamic> json) =>
    _LessonPartDto(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      videoId: json['videoId'] as String?,
      documentUrl: json['documentUrl'] as String?,
      videoDuration: (json['videoDuration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LessonPartDtoToJson(_LessonPartDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'videoId': instance.videoId,
      'documentUrl': instance.documentUrl,
      'videoDuration': instance.videoDuration,
    };

_EnrollmentProgressModel _$EnrollmentProgressModelFromJson(
  Map<String, dynamic> json,
) => _EnrollmentProgressModel(
  enrollmentId: json['enrollmentId'] as String,
  progressPercentage: (json['progressPercentage'] as num).toDouble(),
  completedParts: (json['completedParts'] as num?)?.toInt() ?? 0,
  totalParts: (json['totalParts'] as num?)?.toInt() ?? 0,
  partProgress:
      (json['partProgress'] as List<dynamic>?)
          ?.map(
            (e) => LessonPartProgressModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$EnrollmentProgressModelToJson(
  _EnrollmentProgressModel instance,
) => <String, dynamic>{
  'enrollmentId': instance.enrollmentId,
  'progressPercentage': instance.progressPercentage,
  'completedParts': instance.completedParts,
  'totalParts': instance.totalParts,
  'partProgress': instance.partProgress,
};

_LessonPartProgressModel _$LessonPartProgressModelFromJson(
  Map<String, dynamic> json,
) => _LessonPartProgressModel(
  lessonPartId: json['lessonPartId'] as String,
  lessonPartTitle: json['lessonPartTitle'] as String? ?? '',
  isCompleted: json['isCompleted'] as bool? ?? false,
  watchedDuration: (json['watchedDuration'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$LessonPartProgressModelToJson(
  _LessonPartProgressModel instance,
) => <String, dynamic>{
  'lessonPartId': instance.lessonPartId,
  'lessonPartTitle': instance.lessonPartTitle,
  'isCompleted': instance.isCompleted,
  'watchedDuration': instance.watchedDuration,
};
