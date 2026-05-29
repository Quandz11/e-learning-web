import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_controller.dart';
import '../core/auth/session_state.dart';
import '../core/auth/user_session.dart';
import '../features/chat_notification/data/services/push_notification_service.dart';
import '../features/chat_notification/presentation/controllers/chat_notification_controller.dart';

class RealtimeSyncScope extends ConsumerStatefulWidget {
  const RealtimeSyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RealtimeSyncScope> createState() => _RealtimeSyncScopeState();
}

class _RealtimeSyncScopeState extends ConsumerState<RealtimeSyncScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncFromState(ref.read(sessionControllerProvider)));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    unawaited(
      _syncFromState(ref.read(sessionControllerProvider), forceRefresh: true),
    );
  }

  Future<void> _syncFromState(
    SessionState sessionState, {
    bool forceRefresh = false,
  }) async {
    final session = sessionState.maybeWhen(
      authenticated: (currentSession) => currentSession,
      orElse: () => null,
    );
    await _syncFromSession(session, forceRefresh: forceRefresh);
  }

  Future<void> _syncFromSession(
    UserSession? session, {
    bool forceRefresh = false,
  }) async {
    final controller = ref.read(chatNotificationControllerProvider.notifier);
    final pushNotifications = ref.read(pushNotificationServiceProvider);

    if (session == null) {
      await pushNotifications.clearRegistration();
    } else {
      unawaited(pushNotifications.initializeForSession());
    }

    await controller.initialize(
      accessToken: session?.tokens.accessToken,
      currentUserId: session?.user.id,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionControllerProvider, (_, next) {
      unawaited(_syncFromState(next));
    });

    return widget.child;
  }
}
