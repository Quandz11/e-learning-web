// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeVideoSectionModel _$HomeVideoSectionModelFromJson(
  Map<String, dynamic> json,
) => HomeVideoSectionModel(
  id: json['id'] as String,
  contentHtml: json['contentHtml'] as String?,
  videoType: json['videoType'] as String,
  videoId: json['videoId'] as String?,
  bunnyVideoId: json['bunnyVideoId'] as String?,
  videoUrl: json['videoUrl'] as String?,
);

Map<String, dynamic> _$HomeVideoSectionModelToJson(
  HomeVideoSectionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'contentHtml': instance.contentHtml,
  'videoType': instance.videoType,
  'videoId': instance.videoId,
  'bunnyVideoId': instance.bunnyVideoId,
  'videoUrl': instance.videoUrl,
};

WhyChooseUsModel _$WhyChooseUsModelFromJson(Map<String, dynamic> json) =>
    WhyChooseUsModel(
      id: json['id'] as String,
      icon: json['icon'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      order: (json['order'] as num).toInt(),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$WhyChooseUsModelToJson(WhyChooseUsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'icon': instance.icon,
      'title': instance.title,
      'description': instance.description,
      'order': instance.order,
      'isActive': instance.isActive,
    };
