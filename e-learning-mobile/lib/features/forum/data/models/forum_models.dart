import 'package:freezed_annotation/freezed_annotation.dart';

part 'forum_models.freezed.dart';
part 'forum_models.g.dart';

@freezed
abstract class ForumCategoryModel with _$ForumCategoryModel {
  const factory ForumCategoryModel({
    required String id,
    required String name,
    String? description,
  }) = _ForumCategoryModel;

  factory ForumCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ForumCategoryModelFromJson(json);
}
