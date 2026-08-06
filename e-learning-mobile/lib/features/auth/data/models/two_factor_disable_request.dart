class TwoFactorDisableRequest {
  const TwoFactorDisableRequest({required this.password});

  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{'password': password};
}
