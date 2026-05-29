import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/telemetry/app_logger.dart';
import '../../data/repositories/chat_notification_repository.dart';
import '../../data/services/signalr_service.dart';

const _unset = Object();

@immutable
class ChatNotificationState {
  const ChatNotificationState({
    this.loading = false,
    this.sending = false,
    this.error,
    this.realtimeStatus = RealtimeStatus.disconnected,
    this.conversations = const [],
    this.activeConversationId,
    this.messages = const [],
    this.notifications = const [],
    this.unreadChatCount = 0,
    this.unreadNotificationCount = 0,
  });

  final bool loading;
  final bool sending;
  final String? error;
  final RealtimeStatus realtimeStatus;
  final List<Map<String, dynamic>> conversations;
  final String? activeConversationId;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> notifications;
  final int unreadChatCount;
  final int unreadNotificationCount;

  ChatNotificationState copyWith({
    bool? loading,
    bool? sending,
    Object? error = _unset,
    RealtimeStatus? realtimeStatus,
    List<Map<String, dynamic>>? conversations,
    Object? activeConversationId = _unset,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? notifications,
    int? unreadChatCount,
    int? unreadNotificationCount,
  }) {
    return ChatNotificationState(
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: identical(error, _unset) ? this.error : error as String?,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      conversations: conversations ?? this.conversations,
      activeConversationId: identical(activeConversationId, _unset)
          ? this.activeConversationId
          : activeConversationId as String?,
      messages: messages ?? this.messages,
      notifications: notifications ?? this.notifications,
      unreadChatCount: unreadChatCount ?? this.unreadChatCount,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
    );
  }
}

final chatNotificationControllerProvider =
    StateNotifierProvider<ChatNotificationController, ChatNotificationState>((
      ref,
    ) {
      final controller = ChatNotificationController(
        repository: ref.read(chatNotificationRepositoryProvider),
        signalRService: ref.read(signalRServiceProvider),
        logger: ref.read(appLoggerProvider),
      );
      return controller;
    });

class ChatNotificationController extends StateNotifier<ChatNotificationState> {
  ChatNotificationController({
    required this.repository,
    required this.signalRService,
    required this.logger,
  }) : super(const ChatNotificationState());

  final ChatNotificationRepository repository;
  final SignalRService signalRService;
  final AppLogger logger;

  StreamSubscription<Map<String, dynamic>>? _chatMessageSub;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  StreamSubscription<RealtimeStatus>? _realtimeStatusSub;

  String? _accessToken;
  String? _currentUserId;
  bool _initialized = false;
  bool _listenersBound = false;
  bool _isRefreshingFromReconnect = false;
  bool _hasConnectedOnce = false;
  final Set<String> _seenChatMessageIds = <String>{};
  final Set<String> _seenNotificationIds = <String>{};

  Future<void> initialize({
    required String? accessToken,
    required String? currentUserId,
    bool forceRefresh = false,
  }) async {
    final normalizedToken = accessToken?.trim();
    final normalizedUserId = currentUserId?.trim();
    final hadSession = _currentUserId != null && _currentUserId!.isNotEmpty;
    final hasSession =
        normalizedToken != null &&
        normalizedToken.isNotEmpty &&
        normalizedUserId != null &&
        normalizedUserId.isNotEmpty;
    final userChanged =
        _currentUserId != null &&
        _currentUserId != normalizedUserId &&
        normalizedUserId != null &&
        normalizedUserId.isNotEmpty;

    _accessToken = normalizedToken;
    _currentUserId = normalizedUserId;
    await signalRService.setAccessToken(normalizedToken);
    _bindRealtimeListeners();

    if (!hasSession) {
      if (hadSession || _initialized) {
        await disconnectRealtime();
      }
      _initialized = false;
      state = const ChatNotificationState();
      return;
    }

    final shouldRefresh = forceRefresh || !_initialized || userChanged;
    if (shouldRefresh) {
      await refresh();
    }

    _initialized = true;
    await connectRealtime();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final conversationsFuture = repository.getConversations();
      final notificationsFuture = repository.getNotifications();
      final unreadChatFuture = repository.getUnreadChatCount();

      final results = await Future.wait<dynamic>([
        conversationsFuture,
        notificationsFuture,
        unreadChatFuture,
      ]);

      final conversations = _sortConversations(_normalizeMapList(results[0]));
      final notificationsPayload = _normalizeMap(results[1]);
      final notifications = _normalizeMapList(
        notificationsPayload['notifications'],
      );
      final unreadNotifications = _toInt(notificationsPayload['unreadCount']);

      state = state.copyWith(
        loading: false,
        conversations: conversations,
        notifications: notifications,
        unreadChatCount: _toInt(results[2]),
        unreadNotificationCount: unreadNotifications,
        error: null,
      );
    } catch (error, stackTrace) {
      logger.error('Failed to refresh chat/notifications', error, stackTrace);
      state = state.copyWith(
        loading: false,
        error: 'Failed to load chat or notifications: $error',
      );
    }
  }

  Future<void> connectRealtime() async {
    final token = _accessToken?.trim();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await signalRService.connect(token);
      state = state.copyWith(realtimeStatus: signalRService.status);

      final activeConversationId = state.activeConversationId;
      if (activeConversationId != null && activeConversationId.isNotEmpty) {
        await signalRService.joinConversation(activeConversationId);
      }
    } catch (error, stackTrace) {
      logger.error('Failed to connect realtime', error, stackTrace);
      state = state.copyWith(
        realtimeStatus: RealtimeStatus.error,
        error: 'Realtime connection failed: $error',
      );
    }
  }

  Future<void> disconnectRealtime() async {
    await signalRService.disconnectAll();
    state = state.copyWith(realtimeStatus: RealtimeStatus.disconnected);
  }

  Future<void> openConversation(String conversationId) async {
    if (conversationId.isEmpty) {
      return;
    }

    try {
      final previousConversationId = state.activeConversationId;
      if (previousConversationId != null &&
          previousConversationId != conversationId) {
        await signalRService.leaveConversation(previousConversationId);
      }

      final messages = _normalizeMapList(
        await repository.getMessages(conversationId),
      );
      await signalRService.joinConversation(conversationId);

      state = state.copyWith(
        activeConversationId: conversationId,
        messages: messages,
        error: null,
      );

      await markConversationRead(conversationId, silent: true);
    } catch (error, stackTrace) {
      logger.error('Failed to open conversation', error, stackTrace);
      state = state.copyWith(error: 'Failed to open conversation: $error');
    }
  }

  Future<void> sendActiveConversationMessage(String content) async {
    final conversationId = state.activeConversationId;
    if (conversationId == null || conversationId.isEmpty) {
      state = state.copyWith(error: 'Please select a conversation first.');
      return;
    }

    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      return;
    }

    state = state.copyWith(sending: true, error: null);
    try {
      if (signalRService.isChatConnected) {
        await signalRService.sendMessage(conversationId, normalizedContent);
      } else {
        await repository.sendMessage(conversationId, normalizedContent);
        final refreshed = _normalizeMapList(
          await repository.getMessages(conversationId),
        );
        state = state.copyWith(messages: refreshed);
      }
    } catch (error, stackTrace) {
      logger.error('Failed to send message', error, stackTrace);
      state = state.copyWith(error: 'Send message failed: $error');
    } finally {
      state = state.copyWith(sending: false);
    }
  }

  Future<void> markConversationRead(
    String conversationId, {
    bool silent = false,
  }) async {
    if (conversationId.isEmpty) {
      return;
    }

    final conversations = List<Map<String, dynamic>>.from(state.conversations);
    final index = conversations.indexWhere(
      (conversation) => conversation['id']?.toString() == conversationId,
    );

    int deductedUnread = 0;
    if (index >= 0) {
      final currentUnread = _toInt(conversations[index]['unreadCount']);
      deductedUnread = currentUnread;
      conversations[index] = Map<String, dynamic>.from(conversations[index])
        ..['unreadCount'] = 0;
    }

    final unreadChatCount = (state.unreadChatCount - deductedUnread).clamp(
      0,
      999999,
    );
    state = state.copyWith(
      conversations: conversations,
      unreadChatCount: unreadChatCount,
    );

    try {
      await repository.markConversationRead(conversationId);
      await signalRService.markConversationRead(conversationId);
    } catch (error, stackTrace) {
      logger.error('Failed to mark conversation read', error, stackTrace);
      if (!silent) {
        state = state.copyWith(error: 'Mark conversation read failed: $error');
      }
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (notificationId.isEmpty) {
      return;
    }

    final notifications = List<Map<String, dynamic>>.from(state.notifications);
    final index = notifications.indexWhere(
      (notification) => notification['id']?.toString() == notificationId,
    );

    if (index < 0 || notifications[index]['isRead'] == true) {
      return;
    }

    notifications[index] = Map<String, dynamic>.from(notifications[index])
      ..['isRead'] = true;

    final unread = (state.unreadNotificationCount - 1).clamp(0, 999999);
    state = state.copyWith(
      notifications: notifications,
      unreadNotificationCount: unread,
    );

    try {
      await repository.markNotificationRead(notificationId);
    } catch (error, stackTrace) {
      logger.error('Failed to mark notification read', error, stackTrace);
      state = state.copyWith(error: 'Mark notification read failed: $error');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final notifications = state.notifications
        .map(
          (notification) =>
              Map<String, dynamic>.from(notification)..['isRead'] = true,
        )
        .toList(growable: false);

    state = state.copyWith(
      notifications: notifications,
      unreadNotificationCount: 0,
    );

    try {
      await repository.markAllNotificationsRead();
    } catch (error, stackTrace) {
      logger.error('Failed to mark all notifications read', error, stackTrace);
      state = state.copyWith(
        error: 'Mark all notifications read failed: $error',
      );
    }
  }

  void _bindRealtimeListeners() {
    if (_listenersBound) {
      return;
    }
    _listenersBound = true;

    _chatMessageSub = signalRService.chatMessageStream.listen(_onChatMessage);
    _notificationSub = signalRService.notificationStream.listen(
      _onNotificationMessage,
    );
    _realtimeStatusSub = signalRService.statusStream.listen((status) {
      state = state.copyWith(realtimeStatus: status);
      if (status == RealtimeStatus.connected) {
        final activeConversationId = state.activeConversationId;
        if (activeConversationId != null && activeConversationId.isNotEmpty) {
          unawaited(signalRService.joinConversation(activeConversationId));
        }

        if (_hasConnectedOnce) {
          unawaited(_refreshAfterReconnect());
        } else {
          _hasConnectedOnce = true;
        }
      }
    });
  }

  Future<void> _refreshAfterReconnect() async {
    if (_isRefreshingFromReconnect) {
      return;
    }

    _isRefreshingFromReconnect = true;
    try {
      await refresh();
    } finally {
      _isRefreshingFromReconnect = false;
    }
  }

  void _onChatMessage(Map<String, dynamic> message) {
    final messageId = _extractEntityId(message);
    if (messageId != null && !_trackSeen(_seenChatMessageIds, messageId)) {
      return;
    }

    final conversationId = message['conversationId']?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }

    final senderId = message['senderId']?.toString();
    final isOwnMessage =
        senderId != null && senderId.isNotEmpty && senderId == _currentUserId;
    final isActiveConversation = conversationId == state.activeConversationId;

    final conversations = List<Map<String, dynamic>>.from(state.conversations);
    var index = conversations.indexWhere(
      (conversation) => conversation['id']?.toString() == conversationId,
    );

    if (index < 0) {
      conversations.insert(0, {
        'id': conversationId,
        'title': 'Conversation',
        'unreadCount': isActiveConversation || isOwnMessage ? 0 : 1,
        'lastMessage': message,
        'lastMessageAt': message['sentAt'],
      });
    } else {
      final conversation = Map<String, dynamic>.from(conversations[index]);
      final unreadCount = _toInt(conversation['unreadCount']);
      conversation['lastMessage'] = message;
      conversation['lastMessageAt'] = message['sentAt'];
      if (isActiveConversation || isOwnMessage) {
        conversation['unreadCount'] = 0;
      } else {
        conversation['unreadCount'] = unreadCount + 1;
      }
      conversations.removeAt(index);
      conversations.insert(0, conversation);
    }

    final nextMessages = isActiveConversation
        ? [...state.messages, message]
        : state.messages;

    var unreadChatCount = state.unreadChatCount;
    if (!isOwnMessage && !isActiveConversation) {
      unreadChatCount += 1;
    }

    state = state.copyWith(
      conversations: conversations,
      messages: nextMessages,
      unreadChatCount: unreadChatCount,
      error: null,
    );
  }

  void _onNotificationMessage(Map<String, dynamic> notification) {
    final normalized = Map<String, dynamic>.from(notification);
    final rawId = normalized['id']?.toString();
    if (rawId == null ||
        rawId.isEmpty ||
        rawId == '00000000-0000-0000-0000-000000000000') {
      normalized['id'] = 'broadcast-${DateTime.now().microsecondsSinceEpoch}';
    }

    final notificationId = normalized['id']?.toString();
    if (notificationId != null &&
        notificationId.isNotEmpty &&
        !_trackSeen(_seenNotificationIds, notificationId)) {
      return;
    }

    if (!normalized.containsKey('isRead')) {
      normalized['isRead'] = false;
    }

    final notifications = <Map<String, dynamic>>[
      normalized,
      ...state.notifications,
    ];

    final unread =
        state.unreadNotificationCount + (normalized['isRead'] == true ? 0 : 1);

    state = state.copyWith(
      notifications: notifications,
      unreadNotificationCount: unread,
      error: null,
    );
  }

  List<Map<String, dynamic>> _normalizeMapList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => _normalizeMap(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _normalizeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _sortConversations(
    List<Map<String, dynamic>> conversations,
  ) {
    final sorted = List<Map<String, dynamic>>.from(conversations);
    sorted.sort((left, right) {
      final leftTime =
          DateTime.tryParse(
            left['lastMessageAt']?.toString() ??
                left['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          DateTime.tryParse(
            right['lastMessageAt']?.toString() ??
                right['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightTime.compareTo(leftTime);
    });
    return sorted;
  }

  int _toInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String? _extractEntityId(Map<String, dynamic> payload) {
    final id = payload['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  bool _trackSeen(Set<String> seen, String id) {
    if (seen.contains(id)) {
      return false;
    }
    seen.add(id);
    if (seen.length > 400) {
      seen.remove(seen.first);
    }
    return true;
  }

  @override
  void dispose() {
    _chatMessageSub?.cancel();
    _notificationSub?.cancel();
    _realtimeStatusSub?.cancel();
    unawaited(signalRService.disconnectAll());
    super.dispose();
  }
}
