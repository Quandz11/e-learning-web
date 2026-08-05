import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
      return SessionController(ref.read(sessionRepositoryProvider));
    });

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._repository) : super(const SessionState.initial());

  final SessionRepository _repository;

  Future<void> restore() async {
    state = const SessionState.restoring();
    try {
      final restored = await _repository.restoreSession();
      if (restored == null) {
        state = const SessionState.unauthenticated();
        return;
      }
      state = SessionState.authenticated(restored);
    } catch (_) {
      try {
        await _repository.clear();
      } catch (_) {}
      state = const SessionState.unauthenticated();
    }
  }

  Future<void> setSession(AppSession session) async {
    await _repository.writeSession(session);
    state = SessionState.authenticated(session);
  }

  Future<void> clearSession() async {
    await _repository.clear();
    state = const SessionState.unauthenticated();
  }

  void syncSession(AppSession session) {
    state = SessionState.authenticated(session);
  }
}
