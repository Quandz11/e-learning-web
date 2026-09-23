import 'dart:async';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

final chatSignalRServiceProvider = Provider<ChatSignalRService>((ref) {
  final service = ChatSignalRService(
    config: ref.watch(appConfigProvider),
    sessionRepository: ref.watch(sessionRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

class ChatSignalRService {
  ChatSignalRService({
    required AppConfig config,
    required SessionRepository sessionRepository,
  })  : _config = config,
        _sessionRepository = sessionRepository;

  final AppConfig _config;
  final SessionRepository _sessionRepository;

  HubConnection? _hubConnection;
  Future<void>? _connecting;
  bool _disposed = false;
  int _generation = 0;
  final Set<String> _groups = {};
  final _reconnected = StreamController<void>.broadcast();
  Stream<void> get onReconnected => _reconnected.stream;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _conversationUpdatedController = StreamController<void>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessage> get onReceiveMessage => _messageController.stream;
  Stream<void> get onConversationUpdated => _conversationUpdatedController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _typingController.stream;

  HubConnectionState get connectionState =>
      _hubConnection?.state ?? HubConnectionState.Disconnected;

  Future<void> connect({String? currentUserId}) async {
    if (_disposed || _hubConnection?.state == HubConnectionState.Connected) return;
    final pending = _connecting ??= _connect();
    try { await pending; } finally { if (identical(_connecting, pending)) _connecting = null; }
  }

  Future<void> _connect() async {
    final generation = _generation;
    final previous = _hubConnection;
    _hubConnection = null;
    await previous?.stop();
    if (_disposed || generation != _generation) return;
    final hubUrl = '${_config.apiBaseUrl.toString().replaceFirst(RegExp(r'/api/?$'), '')}/hubs/chat';
    final connection = HubConnectionBuilder().withUrl(hubUrl, options: HttpConnectionOptions(
      accessTokenFactory: () async {
        var session = await _sessionRepository.readStoredSession();
        if (session == null || _disposed || generation != _generation) throw StateError('No active session');
        if (session.isExpiredAt(DateTime.now())) session = await _sessionRepository.refreshStoredSession();
        return session.accessToken;
      },
    )).withAutomaticReconnect().build();
    _hubConnection = connection;
    connection.on('ReceiveMessage', _handleReceiveMessage);
    connection.on('ReceiveGuestMessage', _handleReceiveGuestMessage);
    connection.on('ConversationUpdated', _handleConversationUpdated);
    connection.on('UserTyping', _handleUserTyping);
    connection.onreconnected(({connectionId}) async {
      if (_disposed || generation != _generation) return;
      for (final group in _groups.toList()) { await joinConversation(group); }
      if (!_reconnected.isClosed) _reconnected.add(null);
    });
    try {
      await connection.start();
      if (_disposed || generation != _generation) await connection.stop();
    } catch (_) {
      // HTTP history and sending remain usable while realtime is unavailable.
      debugPrint('[SignalR] Chat connection unavailable');
    }
  }

  void _handleReceiveMessage(List<dynamic>? args) {
    if (_disposed || args == null || args.isEmpty) return;
    try {
      final data = args[0];
      if (data is Map<String, dynamic>) {
        final message = ChatMessage.fromJson(data);
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('[SignalR] Error parsing ReceiveMessage: $e');
    }
  }

  void _handleReceiveGuestMessage(List<dynamic>? args) {
    if (_disposed || args == null || args.length < 2) return;
    try {
      final data = args[1];
      if (data is Map<String, dynamic>) {
        final message = ChatMessage.fromGuestJson(data, args[0].toString());
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('[SignalR] Error parsing ReceiveGuestMessage: $e');
    }
  }

  void _handleConversationUpdated(List<dynamic>? args) {
    if (!_disposed) _conversationUpdatedController.add(null);
  }

  void _handleUserTyping(List<dynamic>? args) {
    if (args != null && args.isNotEmpty) {
      _typingController.add({'userId': args[0], 'isTyping': true});
    }
  }

  Future<void> joinConversation(String conversationId) async {
    _groups.add(conversationId);
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('JoinConversation', args: [conversationId]);
      } catch (e) {
        debugPrint('[SignalR] Error joining conversation: $e');
      }
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    _groups.remove(conversationId);
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('LeaveConversation', args: [conversationId]);
      } catch (e) {
        debugPrint('[SignalR] Error leaving conversation: $e');
      }
    }
  }

  Future<void> disconnect() async {
    _generation++;
    _groups.clear();
    final connection = _hubConnection;
    _hubConnection = null;
    await connection?.stop();
  }

  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    _messageController.close();
    _conversationUpdatedController.close();
    _typingController.close();
    _reconnected.close();
  }
}
