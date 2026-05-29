import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/auth/token_store.dart';
import '../../../../core/config/env_loader.dart';
import '../../../../core/telemetry/app_logger.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) {
  return SignalRService(
    baseApiUrl: ref.read(appEnvProvider).apiBaseUrl,
    logger: ref.read(appLoggerProvider),
    tokenStore: ref.read(tokenStoreProvider),
  );
});

enum RealtimeStatus { disconnected, connecting, connected, reconnecting, error }

class SignalRService {
  SignalRService({
    required String baseApiUrl,
    required this.logger,
    this.tokenStore,
  }) : _hubBaseUrl = baseApiUrl.replaceAll('/api', '');

  final AppLogger logger;
  final String _hubBaseUrl;
  final TokenStore? tokenStore;

  HubConnection? _chatConnection;
  HubConnection? _notificationConnection;
  String? _accessToken;
  bool _isConnecting = false;

  final Set<String> _joinedConversationIds = <String>{};
  final StreamController<Map<String, dynamic>> _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RealtimeStatus> _statusController =
      StreamController<RealtimeStatus>.broadcast();

  Stream<Map<String, dynamic>> get chatMessageStream =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<RealtimeStatus> get statusStream => _statusController.stream;

  RealtimeStatus _status = RealtimeStatus.disconnected;
  RealtimeStatus get status => _status;

  bool get isChatConnected =>
      _chatConnection?.state == HubConnectionState.Connected;

  Future<void> connect([String? token]) async {
    if (token != null && token.trim().isNotEmpty) {
      _accessToken = token.trim();
    }

    final resolvedToken = await _resolveAccessToken();
    if (resolvedToken == null || resolvedToken.isEmpty) {
      _setStatus(RealtimeStatus.disconnected);
      return;
    }

    if (_isConnecting) {
      return;
    }

    _isConnecting = true;
    _setStatus(RealtimeStatus.connecting);

    try {
      _accessToken = resolvedToken;
      _chatConnection ??= _buildChatConnection();
      _notificationConnection ??= _buildNotificationConnection();

      await _ensureStarted(_chatConnection!);
      await _ensureStarted(_notificationConnection!);
      _setStatus(RealtimeStatus.connected);
    } catch (error, stackTrace) {
      logger.error('SignalR connect failed', error, stackTrace);
      _setStatus(RealtimeStatus.error);
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> setAccessToken(String? token) async {
    _accessToken = token?.trim();
  }

  Future<void> reconnect() async {
    final token = await _resolveAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await connect(token);
  }

  Future<void> disconnectAll() async {
    try {
      await _chatConnection?.stop();
      await _notificationConnection?.stop();
    } finally {
      _setStatus(RealtimeStatus.disconnected);
    }
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final connection = _chatConnection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      throw StateError('Chat hub is not connected');
    }

    await connection.invoke(
      'SendMessage',
      args: <Object>[conversationId, content],
    );
  }

  Future<void> joinConversation(String conversationId) async {
    final connection = _chatConnection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      return;
    }

    await connection.invoke('JoinConversation', args: <Object>[conversationId]);
    _joinedConversationIds.add(conversationId);
  }

  Future<void> leaveConversation(String conversationId) async {
    final connection = _chatConnection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      _joinedConversationIds.remove(conversationId);
      return;
    }

    await connection.invoke(
      'LeaveConversation',
      args: <Object>[conversationId],
    );
    _joinedConversationIds.remove(conversationId);
  }

  Future<void> markConversationRead(String conversationId) async {
    final connection = _chatConnection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      return;
    }

    await connection.invoke('MarkAsRead', args: <Object>[conversationId]);
  }

  HubConnection _buildChatConnection() {
    final connection = HubConnectionBuilder()
        .withUrl(
          '$_hubBaseUrl/hubs/chat',
          options: HttpConnectionOptions(accessTokenFactory: _tokenFactory),
        )
        .withAutomaticReconnect(retryDelays: const [1000, 2000, 5000, 10000])
        .build();

    connection.on('ReceiveMessage', (arguments) {
      final payload = _extractMapArgument(arguments);
      if (payload != null) {
        _chatMessageController.add(payload);
      }
    });

    connection.onreconnecting(({error}) {
      logger.warn('Chat hub reconnecting: $error');
      _setStatus(RealtimeStatus.reconnecting);
    });

    connection.onreconnected(({connectionId}) async {
      logger.info('Chat hub reconnected: $connectionId');
      await _restoreConversationGroups(connection);
      _updateStatusFromConnections();
    });

    connection.onclose(({error}) {
      logger.warn('Chat hub closed: $error');
      _updateStatusFromConnections();
    });

    return connection;
  }

  HubConnection _buildNotificationConnection() {
    final connection = HubConnectionBuilder()
        .withUrl(
          '$_hubBaseUrl/hubs/notification',
          options: HttpConnectionOptions(accessTokenFactory: _tokenFactory),
        )
        .withAutomaticReconnect(retryDelays: const [1000, 2000, 5000, 10000])
        .build();

    connection.on('ReceiveNotification', (arguments) {
      final payload = _extractMapArgument(arguments);
      if (payload != null) {
        _notificationController.add(payload);
      }
    });

    connection.onreconnecting(({error}) {
      logger.warn('Notification hub reconnecting: $error');
      _setStatus(RealtimeStatus.reconnecting);
    });

    connection.onreconnected(({connectionId}) {
      logger.info('Notification hub reconnected: $connectionId');
      _updateStatusFromConnections();
    });

    connection.onclose(({error}) {
      logger.warn('Notification hub closed: $error');
      _updateStatusFromConnections();
    });

    return connection;
  }

  Future<String> _tokenFactory() async {
    return (await _resolveAccessToken()) ?? '';
  }

  Future<String?> _resolveAccessToken() async {
    final stored = tokenStore == null ? null : await tokenStore!.read();
    final storedToken = stored?.accessToken.trim();
    if (storedToken != null && storedToken.isNotEmpty) {
      return storedToken;
    }

    final fallback = _accessToken?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }

  Future<void> _ensureStarted(HubConnection connection) async {
    final current = connection.state;
    if (current == HubConnectionState.Connected ||
        current == HubConnectionState.Connecting ||
        current == HubConnectionState.Reconnecting) {
      return;
    }

    await connection.start();
  }

  Future<void> _restoreConversationGroups(HubConnection connection) async {
    if (_joinedConversationIds.isEmpty) {
      return;
    }

    for (final conversationId in _joinedConversationIds) {
      try {
        await connection.invoke(
          'JoinConversation',
          args: <Object>[conversationId],
        );
      } catch (error, stackTrace) {
        logger.error(
          'Failed to restore conversation group $conversationId',
          error,
          stackTrace,
        );
      }
    }
  }

  Map<String, dynamic>? _extractMapArgument(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    final first = arguments.first;
    if (first is Map<String, dynamic>) {
      return first;
    }

    if (first is Map) {
      return first.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  void _updateStatusFromConnections() {
    final chatState = _chatConnection?.state;
    final notificationState = _notificationConnection?.state;

    if (chatState == HubConnectionState.Reconnecting ||
        notificationState == HubConnectionState.Reconnecting) {
      _setStatus(RealtimeStatus.reconnecting);
      return;
    }

    if (chatState == HubConnectionState.Connecting ||
        notificationState == HubConnectionState.Connecting) {
      _setStatus(RealtimeStatus.connecting);
      return;
    }

    if (chatState == HubConnectionState.Connected &&
        notificationState == HubConnectionState.Connected) {
      _setStatus(RealtimeStatus.connected);
      return;
    }

    if (chatState == HubConnectionState.Connected ||
        notificationState == HubConnectionState.Connected) {
      _setStatus(RealtimeStatus.reconnecting);
      return;
    }

    _setStatus(RealtimeStatus.disconnected);
  }

  void _setStatus(RealtimeStatus next) {
    if (_status == next) {
      return;
    }

    _status = next;
    _statusController.add(next);
  }
}
