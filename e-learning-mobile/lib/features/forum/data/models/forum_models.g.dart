// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ForumCategoryModel _$ForumCategoryModelFromJson(Map<String, dynamic> json) =>
    _ForumCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ForumCategoryModelToJson(_ForumCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };
