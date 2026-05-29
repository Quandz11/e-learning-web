import 'package:freezed_annotation/freezed_annotation.dart';

part 'wellness_ai_models.freezed.dart';
part 'wellness_ai_models.g.dart';

@freezed
abstract class AiStatusModel with _$AiStatusModel {
  const factory AiStatusModel({
    required bool isEnabled,
    Map<String, dynamic>? access,
  }) = _AiStatusModel;

  factory AiStatusModel.fromJson(Map<String, dynamic> json) =>
      _$AiStatusModelFromJson(json);
}
