import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_notification_models.freezed.dart';
part 'chat_notification_models.g.dart';

@freezed
abstract class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String id,
    required String content,
    required String senderId,
    required DateTime sentAt,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);
}
