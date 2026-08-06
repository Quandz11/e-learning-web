enum SecurityStatus {
  idle,
  loadingSetup,
  setupReady,
  enabling,
  disabling,
  success,
  failure,
}

class SecurityState {
  const SecurityState({
    this.status = SecurityStatus.idle,
    this.secret,
    this.qrCodeUri,
    this.codeError,
    this.passwordError,
    this.generalMessage,
  });

  final SecurityStatus status;
  final String? secret;
  final String? qrCodeUri;
  final String? codeError;
  final String? passwordError;
  final String? generalMessage;

  bool get isBusy =>
      status == SecurityStatus.loadingSetup ||
      status == SecurityStatus.enabling ||
      status == SecurityStatus.disabling;
}
