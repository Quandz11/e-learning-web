import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_models.freezed.dart';
part 'course_models.g.dart';

@freezed
abstract class CourseSummaryModel with _$CourseSummaryModel {
  const factory CourseSummaryModel({
    required String id,
    required String title,
    String? thumbnailUrl,
    required bool isFree,
    required double price,
  }) = _CourseSummaryModel;

  factory CourseSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$CourseSummaryModelFromJson(json);
}

@freezed
abstract class CourseDetailModel with _$CourseDetailModel {
  const factory CourseDetailModel({
    required String id,
    required String title,
    String? description,
    required bool isFree,
    required double price,
    @Default([]) List<LessonDto> lessons,
  }) = _CourseDetailModel;

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailModelFromJson(json);
}

@freezed
abstract class LessonDto with _$LessonDto {
  const factory LessonDto({
    required String id,
    required String title,
    @Default([]) List<LessonPartDto> parts,
  }) = _LessonDto;

  factory LessonDto.fromJson(Map<String, dynamic> json) =>
      _$LessonDtoFromJson(json);
}

@freezed
abstract class LessonPartDto with _$LessonPartDto {
  const factory LessonPartDto({
    required String id,
    required String title,
    required String type, // Video, Document
    String? videoId,
    String? documentUrl,
    int? videoDuration,
  }) = _LessonPartDto;

  factory LessonPartDto.fromJson(Map<String, dynamic> json) =>
      _$LessonPartDtoFromJson(json);
}

@freezed
abstract class EnrollmentProgressModel with _$EnrollmentProgressModel {
  const factory EnrollmentProgressModel({
    required String enrollmentId,
    required double progressPercentage,
    @Default(0) int completedParts,
    @Default(0) int totalParts,
    @Default([]) List<LessonPartProgressModel> partProgress,
  }) = _EnrollmentProgressModel;

  factory EnrollmentProgressModel.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentProgressModelFromJson(json);
}

@freezed
abstract class LessonPartProgressModel with _$LessonPartProgressModel {
  const factory LessonPartProgressModel({
    required String lessonPartId,
    @Default('') String lessonPartTitle,
    @Default(false) bool isCompleted,
    @Default(0) int watchedDuration,
  }) = _LessonPartProgressModel;

  factory LessonPartProgressModel.fromJson(Map<String, dynamic> json) =>
      _$LessonPartProgressModelFromJson(json);
}
