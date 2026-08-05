class TwoFactorLoginRequest {
  const TwoFactorLoginRequest({required this.code});

  final String code;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'code': code};
  }
}
