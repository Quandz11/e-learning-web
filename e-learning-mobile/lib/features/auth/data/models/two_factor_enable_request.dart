class TwoFactorEnableRequest {
  const TwoFactorEnableRequest({required this.secret, required this.code});

  final String secret;
  final String code;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'secret': secret,
    'code': code,
  };
}
