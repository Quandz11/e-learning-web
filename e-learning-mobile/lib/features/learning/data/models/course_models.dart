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
  }) = _CourseDetailModel;

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailModelFromJson(json);
}

@freezed
abstract class EnrollmentProgressModel with _$EnrollmentProgressModel {
  const factory EnrollmentProgressModel({
    required String enrollmentId,
    required double progressPercentage,
  }) = _EnrollmentProgressModel;

  factory EnrollmentProgressModel.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentProgressModelFromJson(json);
}
