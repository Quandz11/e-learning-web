import 'package:json_annotation/json_annotation.dart';

part 'home_models.g.dart';

@JsonSerializable()
class HomeVideoSectionModel {
  final String id;
  final String? contentHtml;
  final String videoType;
  final String? videoId;
  final String? bunnyVideoId;
  final String? videoUrl;

  HomeVideoSectionModel({
    required this.id,
    this.contentHtml,
    required this.videoType,
    this.videoId,
    this.bunnyVideoId,
    this.videoUrl,
  });

  factory HomeVideoSectionModel.fromJson(Map<String, dynamic> json) =>
      _$HomeVideoSectionModelFromJson(json);

  Map<String, dynamic> toJson() => _$HomeVideoSectionModelToJson(this);
}

@JsonSerializable()
class WhyChooseUsModel {
  final String id;
  final String icon;
  final String title;
  final String description;
  final int order;
  final bool isActive;

  WhyChooseUsModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.order,
    required this.isActive,
  });

  factory WhyChooseUsModel.fromJson(Map<String, dynamic> json) =>
      _$WhyChooseUsModelFromJson(json);

  Map<String, dynamic> toJson() => _$WhyChooseUsModelToJson(this);
}
