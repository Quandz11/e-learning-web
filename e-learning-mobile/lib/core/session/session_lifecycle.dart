import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/app_config.dart';
import '../network/network_providers.dart';
import 'session_controller.dart';
import 'session_repository.dart';
import 'session_state.dart';

/// Owns the session channel even when no chat screen is mounted.
class SessionLifecycle extends ConsumerStatefulWidget {
  const SessionLifecycle({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<SessionLifecycle> createState() => _SessionLifecycleState();
}

class _SessionLifecycleState extends ConsumerState<SessionLifecycle>
    with WidgetsBindingObserver {
  HubConnection? _connection;
  String? _sessionId;
  Timer? _timer;
  bool _checking = false;
  int _generation = 0;

  bool get _isRealApp => WidgetsBinding.instance is WidgetsFlutterBinding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual<SessionState>(
      sessionControllerProvider,
      (_, state) => _sync(state.session?.sessionId),
      fireImmediately: true,
    );
    if (_isRealApp) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _verify());
    }
  }

  Future<void> _sync(String? id) async {
    if (id == _sessionId) return;
    _sessionId = id;
    final generation = ++_generation;
    final previous = _connection;
    _connection = null;
    await previous?.stop();
    if (!mounted || generation != _generation || id == null || !_isRealApp) {
      return;
    }
    await _verify();
    if (!mounted || generation != _generation) {
      return;
    }
    final repository = ref.read(sessionRepositoryProvider);
    final base = ref
        .read(appConfigProvider)
        .apiBaseUrl
        .toString()
        .replaceFirst(RegExp(r'/api/?$'), '');
    final connection = HubConnectionBuilder()
        .withUrl(
          '$base/hubs/notification',
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              var session = await repository.readStoredSession();
              if (session == null || session.sessionId != id) {
                throw StateError('Session changed');
              }
              if (session.isExpiredAt(DateTime.now())) {
                session = await repository.refreshStoredSession();
              }
              return session.accessToken;
            },
          ),
        )
        .withAutomaticReconnect()
        .build();
    _connection = connection;
    connection.on('SessionRevoked', (args) {
      if (!mounted ||
          generation != _generation ||
          args == null ||
          args.isEmpty) {
        return;
      }
      final event = args.first;
      if (event is Map && event['sessionId'] == id) {
        unawaited(ref.read(sessionControllerProvider.notifier).clearSession());
      }
    });
    connection.onreconnected(({connectionId}) => _verify());
    connection.onclose(({error}) => _verify());
    try {
      await connection.start();
      if (!mounted || generation != _generation) await connection.stop();
    } catch (_) {
      /* HTTP validation is the fallback while realtime is unavailable. */
    }
  }

  Future<void> _verify() async {
    if (!mounted || _sessionId == null || _checking) return;
    _checking = true;
    try {
      await ref.read(apiClientProvider).get<Object?>('/auth/sessions');
    } catch (_) {
      /* The auth interceptor handles revocation; network errors keep the session. */
    } finally {
      _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_verify());
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connection?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
