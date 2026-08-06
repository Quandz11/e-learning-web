class PhoneForgotPasswordOtpRequest {
  const PhoneForgotPasswordOtpRequest({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'phone': phone};
  }
}
