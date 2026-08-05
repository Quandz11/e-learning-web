class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    this.referralCode,
  });

  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final String? referralCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'referralCode': referralCode,
    };
  }
}
