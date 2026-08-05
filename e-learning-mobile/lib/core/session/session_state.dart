import 'package:e_learning_mobile/core/session/app_session.dart';

enum SessionStatus { initial, restoring, authenticated, unauthenticated }

class SessionState {
  const SessionState._({required this.status, this.session});

  const SessionState.initial() : this._(status: SessionStatus.initial);

  const SessionState.restoring() : this._(status: SessionStatus.restoring);

  const SessionState.authenticated(AppSession session)
    : this._(status: SessionStatus.authenticated, session: session);

  const SessionState.unauthenticated()
    : this._(status: SessionStatus.unauthenticated);

  final SessionStatus status;
  final AppSession? session;

  bool get isAuthenticated =>
      status == SessionStatus.authenticated && session != null;

  bool get isRestoring =>
      status == SessionStatus.initial || status == SessionStatus.restoring;
}
