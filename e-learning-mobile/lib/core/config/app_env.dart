class AppEnv {
  const AppEnv({
    required this.apiBaseUrl,
    required this.flavor,
    required this.paymentReturnUrl,
    required this.paymentCancelUrl,
  });

  final String apiBaseUrl;
  final String flavor;
  final String paymentReturnUrl;
  final String paymentCancelUrl;
}
