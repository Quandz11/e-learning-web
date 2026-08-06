import 'package:e_learning_mobile/core/errors/app_failure.dart';

class TwoFactorSetupResponse {
  const TwoFactorSetupResponse({required this.secret, required this.qrCodeUri});

  factory TwoFactorSetupResponse.fromJson(Map<String, dynamic> json) {
    final secret = json['secret'];
    final qrCodeUri = json['qrCodeUri'];
    if (secret is! String || secret.trim().isEmpty) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid response.',
        debugDetails: 'Missing 2FA secret.',
      );
    }
    if (qrCodeUri is! String || qrCodeUri.trim().isEmpty) {
      throw const AppFailure(
        type: AppFailureType.malformedResponse,
        message: 'The server returned an invalid response.',
        debugDetails: 'Missing 2FA QR URI.',
      );
    }

    return TwoFactorSetupResponse(
      secret: secret.trim(),
      qrCodeUri: qrCodeUri.trim(),
    );
  }

  final String secret;
  final String qrCodeUri;
}
