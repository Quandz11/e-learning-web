class ForgotPasswordChallenge {
  const ForgotPasswordChallenge({
    this.phone,
    this.email,
  });

  final String? phone;
  final String? email;

  bool get isEmail => email != null && email!.trim().isNotEmpty;
  String get target => isEmail ? email!.trim() : (phone?.trim() ?? '');
  bool get isValid => target.isNotEmpty;
}
