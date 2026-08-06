class ForgotPasswordChallenge {
  const ForgotPasswordChallenge({required this.phone});

  final String phone;

  bool get isValid => phone.trim().isNotEmpty;
}
