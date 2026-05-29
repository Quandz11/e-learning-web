import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/network/network_providers.dart';
import 'package:e_learning_mobile/core/telemetry/app_logger.dart';
import 'package:e_learning_mobile/features/chat_notification/data/repositories/chat_notification_repository.dart';
import 'package:e_learning_mobile/features/chat_notification/data/services/signalr_service.dart';
import 'package:e_learning_mobile/features/chat_notification/presentation/controllers/chat_notification_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeChatNotificationRepository repository;
  late FakeSignalRService signalRService;
  late ChatNotificationController controller;

  setUp(() {
    repository = FakeChatNotificationRepository();
    signalRService = FakeSignalRService();
    controller = ChatNotificationController(
      repository: repository,
      signalRService: signalRService,
      logger: const AppLogger(),
    );
  });

  tearDown(() async {
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    signalRService.disposeFake();
  });

  test('initialize should refresh data and connect realtime', () async {
    repository.conversations = [
      {
        'id': 'c1',
        'title': 'Thread A',
        'unreadCount': 0,
        'lastMessageAt': '2026-01-01T00:00:00Z',
      },
    ];
    repository.notificationsPayload = {
      'notifications': <Map<String, dynamic>>[],
      'unreadCount': 0,
    };
    repository.unreadChatCount = 0;

    await controller.initialize(accessToken: 'token-1', currentUserId: 'u1');

    expect(signalRService.connectCalls, 1);
    expect(signalRService.lastToken, 'token-1');
    expect(controller.state.realtimeStatus, RealtimeStatus.connected);
    expect(controller.state.conversations.length, 1);
  });

  test('incoming message from another user increments unread count', () async {
    repository.conversations = [
      {
        'id': 'c1',
        'title': 'Thread A',
        'unreadCount': 0,
        'lastMessageAt': '2026-01-01T00:00:00Z',
      },
    ];
    repository.notificationsPayload = {
      'notifications': <Map<String, dynamic>>[],
      'unreadCount': 0,
    };
    repository.unreadChatCount = 0;

    await controller.initialize(accessToken: 'token-1', currentUserId: 'u1');

    signalRService.emitChatMessage({
      'conversationId': 'c1',
      'senderId': 'u2',
      'senderName': 'User 2',
      'content': 'hello',
      'sentAt': '2026-01-02T00:00:00Z',
    });
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.unreadChatCount, 1);
    expect(controller.state.conversations.first['unreadCount'], 1);
  });

  test('incoming own message does not increment unread count', () async {
    repository.conversations = [
      {
        'id': 'c1',
        'title': 'Thread A',
        'unreadCount': 0,
        'lastMessageAt': '2026-01-01T00:00:00Z',
      },
    ];
    repository.notificationsPayload = {
      'notifications': <Map<String, dynamic>>[],
      'unreadCount': 0,
    };
    repository.unreadChatCount = 0;

    await controller.initialize(accessToken: 'token-1', currentUserId: 'u1');

    signalRService.emitChatMessage({
      'conversationId': 'c1',
      'senderId': 'u1',
      'senderName': 'Me',
      'content': 'my message',
      'sentAt': '2026-01-02T00:00:00Z',
    });
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.unreadChatCount, 0);
    expect(controller.state.conversations.first['unreadCount'], 0);
  });

  test('duplicate realtime message id is ignored', () async {
    repository.conversations = [
      {
        'id': 'c1',
        'title': 'Thread A',
        'unreadCount': 0,
        'lastMessageAt': '2026-01-01T00:00:00Z',
      },
    ];
    repository.notificationsPayload = {
      'notifications': <Map<String, dynamic>>[],
      'unreadCount': 0,
    };
    repository.unreadChatCount = 0;

    await controller.initialize(accessToken: 'token-1', currentUserId: 'u1');

    final message = {
      'id': 'm-1',
      'conversationId': 'c1',
      'senderId': 'u2',
      'senderName': 'User 2',
      'content': 'hello',
      'sentAt': '2026-01-02T00:00:00Z',
    };

    signalRService.emitChatMessage(message);
    signalRService.emitChatMessage(message);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.unreadChatCount, 1);
    expect(controller.state.conversations.first['unreadCount'], 1);
  });

  test('duplicate notification id is ignored', () async {
    repository.conversations = <Map<String, dynamic>>[];
    repository.notificationsPayload = {
      'notifications': <Map<String, dynamic>>[],
      'unreadCount': 0,
    };
    repository.unreadChatCount = 0;

    await controller.initialize(accessToken: 'token-1', currentUserId: 'u1');

    final notification = {
      'id': 'n-1',
      'title': 'Notice',
      'content': 'payload',
      'isRead': false,
      'createdAt': '2026-01-01T00:00:00Z',
    };
    signalRService.emitNotification(notification);
    signalRService.emitNotification(notification);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.notifications.length, 1);
    expect(controller.state.unreadNotificationCount, 1);
  });

  test(
    'markNotificationRead updates unread counter and calls repository',
    () async {
      repository.conversations = <Map<String, dynamic>>[];
      repository.notificationsPayload = {
        'notifications': [
          {
            'id': 'n1',
            'title': 'N1',
            'content': 'Body',
            'isRead': false,
            'createdAt': '2026-01-01T00:00:00Z',
          },
        ],
        'unreadCount': 1,
      };
      repository.unreadChatCount = 0;

      await controller.initialize(accessToken: 'token-1', currentUserId: 'u1');
      await controller.markNotificationRead('n1');

      expect(controller.state.unreadNotificationCount, 0);
      expect(repository.markedNotificationIds, ['n1']);
    },
  );

  test('initialize with null session clears state and disconnects', () async {
    repository.conversations = [
      {
        'id': 'c1',
        'title': 'Thread A',
        'unreadCount': 0,
        'lastMessageAt': '2026-01-01T00:00:00Z',
      },
    ];
    repository.notificationsPayload = {
      'notifications': <Map<String, dynamic>>[],
      'unreadCount': 0,
    };
    repository.unreadChatCount = 0;

    await controller.initialize(accessToken: 'token-1', currentUserId: 'u1');
    await controller.initialize(accessToken: null, currentUserId: null);

    expect(signalRService.disconnectCalls, greaterThanOrEqualTo(1));
    expect(controller.state.conversations, isEmpty);
    expect(controller.state.notifications, isEmpty);
    expect(controller.state.unreadChatCount, 0);
    expect(controller.state.unreadNotificationCount, 0);
    expect(controller.state.realtimeStatus, RealtimeStatus.disconnected);
  });
}

class FakeChatNotificationRepository extends ChatNotificationRepository {
  FakeChatNotificationRepository() : super(ApiClient(Dio()));

  List<Map<String, dynamic>> conversations = <Map<String, dynamic>>[];
  Map<String, dynamic> notificationsPayload = <String, dynamic>{
    'notifications': <Map<String, dynamic>>[],
    'unreadCount': 0,
  };
  int unreadChatCount = 0;
  final List<String> markedNotificationIds = <String>[];

  @override
  Future<List<Map<String, dynamic>>> getConversations() async {
    return conversations;
  }

  @override
  Future<Map<String, dynamic>> getNotifications() async {
    return notificationsPayload;
  }

  @override
  Future<int> getUnreadChatCount() async {
    return unreadChatCount;
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    return <Map<String, dynamic>>[];
  }

  @override
  Future<void> markConversationRead(String conversationId) async {}

  @override
  Future<void> sendMessage(String conversationId, String content) async {}

  @override
  Future<void> markNotificationRead(String notificationId) async {
    markedNotificationIds.add(notificationId);
  }

  @override
  Future<void> markAllNotificationsRead() async {}
}

class FakeSignalRService extends SignalRService {
  FakeSignalRService()
    : super(baseApiUrl: 'https://example.com/api', logger: const AppLogger());

  final StreamController<Map<String, dynamic>> _chatController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RealtimeStatus> _statusController =
      StreamController<RealtimeStatus>.broadcast();

  RealtimeStatus _currentStatus = RealtimeStatus.disconnected;
  bool _connected = false;

  int connectCalls = 0;
  int disconnectCalls = 0;
  String? lastToken;

  @override
  Stream<Map<String, dynamic>> get chatMessageStream => _chatController.stream;

  @override
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  @override
  Stream<RealtimeStatus> get statusStream => _statusController.stream;

  @override
  RealtimeStatus get status => _currentStatus;

  @override
  bool get isChatConnected => _connected;

  @override
  Future<void> setAccessToken(String? token) async {
    lastToken = token;
  }

  @override
  Future<void> connect([String? token]) async {
    connectCalls += 1;
    lastToken = token;
    _connected = true;
    _currentStatus = RealtimeStatus.connected;
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
  }

  @override
  Future<void> disconnectAll() async {
    disconnectCalls += 1;
    _connected = false;
    _currentStatus = RealtimeStatus.disconnected;
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
  }

  @override
  Future<void> joinConversation(String conversationId) async {}

  @override
  Future<void> leaveConversation(String conversationId) async {}

  @override
  Future<void> markConversationRead(String conversationId) async {}

  @override
  Future<void> sendMessage(String conversationId, String content) async {}

  void emitChatMessage(Map<String, dynamic> message) {
    if (!_chatController.isClosed) {
      _chatController.add(message);
    }
  }

  void emitNotification(Map<String, dynamic> notification) {
    if (!_notificationController.isClosed) {
      _notificationController.add(notification);
    }
  }

  void disposeFake() {
    _chatController.close();
    _notificationController.close();
    _statusController.close();
  }
}
