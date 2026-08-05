import 'package:e_learning_mobile/core/errors/app_failure.dart';

class MessageResponse {
  const MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    if (message is! String || message.trim().isEmpty) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid response.',
        debugDetails: 'Missing message field in auth response.',
      );
    }

    return MessageResponse(message: message);
  }

  final String message;
}
