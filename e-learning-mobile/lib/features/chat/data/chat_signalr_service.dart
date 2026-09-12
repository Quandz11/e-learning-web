import 'dart:async';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

final chatSignalRServiceProvider = Provider<ChatSignalRService>((ref) {
  return ChatSignalRService(
    config: ref.watch(appConfigProvider),
    sessionRepository: ref.watch(sessionRepositoryProvider),
  );
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
  bool _isConnecting = false;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _conversationUpdatedController = StreamController<void>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessage> get onReceiveMessage => _messageController.stream;
  Stream<void> get onConversationUpdated => _conversationUpdatedController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _typingController.stream;

  HubConnectionState get connectionState =>
      _hubConnection?.state ?? HubConnectionState.Disconnected;

  Future<void> connect({String? currentUserId}) async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;
    if (_isConnecting) return;

    _isConnecting = true;
    try {
      final session = await _sessionRepository.readStoredSession();
      final token = session?.accessToken ?? '';

      var baseUrl = _config.apiBaseUrl.toString();
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      if (baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      }

      final hubUrl = '$baseUrl/hubs/chat';

      final httpOptions = HttpConnectionOptions(
        accessTokenFactory: () async => token,
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
      );

      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl, options: httpOptions)
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('ReceiveMessage', _handleReceiveMessage);
      _hubConnection!.on('ReceiveGuestMessage', _handleReceiveGuestMessage);
      _hubConnection!.on('ConversationUpdated', _handleConversationUpdated);
      _hubConnection!.on('UserTyping', _handleUserTyping);

      await _hubConnection!.start();
      debugPrint('[SignalR] Connected successfully to $hubUrl');
    } catch (e) {
      debugPrint('[SignalR] Connection error: $e');
    } finally {
      _isConnecting = false;
    }
  }

  void _handleReceiveMessage(List<dynamic>? args) {
    if (args == null || args.isEmpty) return;
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
    if (args == null || args.length < 2) return;
    try {
      final data = args[1];
      if (data is Map<String, dynamic>) {
        final message = ChatMessage.fromJson(data);
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('[SignalR] Error parsing ReceiveGuestMessage: $e');
    }
  }

  void _handleConversationUpdated(List<dynamic>? args) {
    _conversationUpdatedController.add(null);
  }

  void _handleUserTyping(List<dynamic>? args) {
    if (args != null && args.isNotEmpty) {
      _typingController.add({'userId': args[0], 'isTyping': true});
    }
  }

  Future<void> joinConversation(String conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('JoinConversation', args: [conversationId]);
      } catch (e) {
        debugPrint('[SignalR] Error joining conversation: $e');
      }
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('LeaveConversation', args: [conversationId]);
      } catch (e) {
        debugPrint('[SignalR] Error leaving conversation: $e');
      }
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null &&
        _hubConnection!.state != HubConnectionState.Disconnected) {
      try {
        await _hubConnection!.stop();
      } catch (_) {}
      _hubConnection = null;
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _conversationUpdatedController.close();
    _typingController.close();
  }
}
