// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wellness_ai_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiStatusModel _$AiStatusModelFromJson(Map<String, dynamic> json) =>
    _AiStatusModel(
      isEnabled: json['isEnabled'] as bool,
      access: json['access'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AiStatusModelToJson(_AiStatusModel instance) =>
    <String, dynamic>{
      'isEnabled': instance.isEnabled,
      'access': instance.access,
    };
