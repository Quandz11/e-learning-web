class PhoneForgotPasswordOtpVerifyRequest {
  const PhoneForgotPasswordOtpVerifyRequest({
    required this.phone,
    required this.otp,
    required this.newPassword,
  });

  final String phone;
  final String otp;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phone': phone,
      'otp': otp,
      'newPassword': newPassword,
    };
  }
}
