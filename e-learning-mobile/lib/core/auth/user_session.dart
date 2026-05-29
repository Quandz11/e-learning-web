import 'package:freezed_annotation/freezed_annotation.dart';

import '../../features/auth/data/models/auth_user_model.dart';
import 'auth_tokens.dart';

part 'user_session.freezed.dart';
part 'user_session.g.dart';

@freezed
abstract class UserSession with _$UserSession {
  const factory UserSession({
    required AuthUserModel user,
    required AuthTokens tokens,
  }) = _UserSession;

  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);
}
