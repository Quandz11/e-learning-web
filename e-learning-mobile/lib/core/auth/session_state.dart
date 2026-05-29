import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_session.dart';

part 'session_state.freezed.dart';

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState.initial() = _Initial;
  const factory SessionState.authenticated(UserSession session) =
      _Authenticated;
  const factory SessionState.unauthenticated() = _Unauthenticated;
  const factory SessionState.loading() = _Loading;
}
