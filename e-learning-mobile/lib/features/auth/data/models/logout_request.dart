class LogoutRequest {
  const LogoutRequest({this.refreshToken});

  final String? refreshToken;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'refreshToken': refreshToken};
  }
}
