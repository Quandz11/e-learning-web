import 'package:e_learning_mobile/features/chat/data/chat_signalr_service.dart';
import 'package:e_learning_mobile/features/chat/presentation/controllers/admin_chat_controller.dart';
import 'package:e_learning_mobile/features/chat/presentation/controllers/admin_chat_detail_controller.dart';
import 'package:e_learning_mobile/features/profile/data/device_sessions_repository.dart';
import 'package:e_learning_mobile/core/network/cache_service.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/features/articles/presentation/controllers/articles_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/forgot_password_challenge_controller.dart';
import 'package:e_learning_mobile/features/chat/presentation/controllers/chat_controller.dart';
import 'package:e_learning_mobile/features/forum/presentation/controllers/forum_controller.dart';
import 'package:e_learning_mobile/features/home/presentation/controllers/home_controller.dart';
import 'package:e_learning_mobile/features/learning/presentation/controllers/learning_controller.dart';
import 'package:e_learning_mobile/features/notifications/data/notifications_repository.dart';
import 'package:e_learning_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:e_learning_mobile/features/personalization/presentation/controllers/wellness_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/progress/presentation/controllers/progress_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
      return SessionController(ref.read(sessionRepositoryProvider), ref);
    });

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._repository, [this._ref])
    : super(const SessionState.initial());

  final SessionRepository _repository;
  final Ref? _ref;
  bool _isClearingSession = false;

  Future<void> restore() async {
    state = const SessionState.restoring();
    try {
      final restored = await _repository.restoreSession();
      if (restored == null) {
        state = const SessionState.unauthenticated();
        return;
      }
      state = SessionState.authenticated(restored);
      _ref?.read(notificationsRepositoryProvider).syncCurrentDeviceToken();
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
    _ref?.read(notificationsRepositoryProvider).syncCurrentDeviceToken();
  }

  Future<void> clearSession() async {
    if (_isClearingSession) return;
    if (state == const SessionState.unauthenticated()) {
      return;
    }
    _isClearingSession = true;

    // Fire-and-forget background unregister (non-blocking for 100% instant logout)
    try {
      _ref
          ?.read(notificationsRepositoryProvider)
          .unregisterCurrentDeviceToken();
    } catch (_) {}

    try {
      await _repository.clear();
      state = const SessionState.unauthenticated();
      final ref = _ref;
      if (ref != null) {
        await ref.read(chatSignalRServiceProvider).disconnect();
        ref.invalidate(adminChatListControllerProvider);
        ref.invalidate(adminChatDetailProvider);
        ref.invalidate(deviceSessionsProvider);
        try {
          await ref.read(cacheServiceProvider).clear();
        } catch (_) {}
        ref.invalidate(homeControllerProvider);
        ref.invalidate(learningControllerProvider);
        ref.invalidate(profileControllerProvider);
        ref.invalidate(progressControllerProvider);
        ref.invalidate(chatControllerProvider);
        ref.invalidate(wellnessControllerProvider);
        ref.invalidate(forumControllerProvider);
        ref.invalidate(notificationsControllerProvider);
        ref.invalidate(articlesControllerProvider);
        ref.invalidate(authOtpChallengeControllerProvider);
        ref.invalidate(forgotPasswordChallengeControllerProvider);
      }
    } finally {
      state = const SessionState.unauthenticated();
      _isClearingSession = false;
    }
  }

  void syncSession(AppSession session) {
    state = SessionState.authenticated(session);
    _ref?.read(notificationsRepositoryProvider).syncCurrentDeviceToken();
  }
}
