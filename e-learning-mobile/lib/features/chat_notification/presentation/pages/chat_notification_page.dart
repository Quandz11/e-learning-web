import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/services/signalr_service.dart';
import '../controllers/chat_notification_controller.dart';

class ChatNotificationPage extends ConsumerStatefulWidget {
  const ChatNotificationPage({super.key});

  @override
  ConsumerState<ChatNotificationPage> createState() =>
      _ChatNotificationPageState();
}

class _ChatNotificationPageState extends ConsumerState<ChatNotificationPage> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref
          .read(sessionControllerProvider.notifier)
          .sessionOrNull;
      final controller = ref.read(chatNotificationControllerProvider.notifier);
      controller.initialize(
        accessToken: session?.tokens.accessToken,
        currentUserId: session?.user.id,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionControllerProvider);
    final session = ref.read(sessionControllerProvider.notifier).sessionOrNull;
    final state = ref.watch(chatNotificationControllerProvider);
    final controller = ref.read(chatNotificationControllerProvider.notifier);

    if (session == null) {
      return const AppScaffold(
        title: 'Chat & Notification',
        child: Center(
          child: Text('Please sign in to use chat and notifications.'),
        ),
      );
    }

    return AppScaffold(
      title: 'Chat & Notification',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: _RealtimeStatusCard(
                status: state.realtimeStatus,
                unreadChatCount: state.unreadChatCount,
                unreadNotificationCount: state.unreadNotificationCount,
                loading: state.loading,
                onConnect: controller.connectRealtime,
                onDisconnect: controller.disconnectRealtime,
                onRefresh: controller.refresh,
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const TabBar(
              tabs: [
                Tab(text: 'Chat'),
                Tab(text: 'Notifications'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ChatTab(
                    state: state,
                    onOpenConversation: controller.openConversation,
                    onMarkConversationRead: controller.markConversationRead,
                    messageController: _messageController,
                    sending: state.sending,
                    onSend: () async {
                      final content = _messageController.text;
                      _messageController.clear();
                      await controller.sendActiveConversationMessage(content);
                    },
                  ),
                  _NotificationTab(
                    state: state,
                    onMarkRead: controller.markNotificationRead,
                    onMarkAllRead: controller.markAllNotificationsRead,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealtimeStatusCard extends StatelessWidget {
  const _RealtimeStatusCard({
    required this.status,
    required this.unreadChatCount,
    required this.unreadNotificationCount,
    required this.loading,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
  });

  final RealtimeStatus status;
  final int unreadChatCount;
  final int unreadNotificationCount;
  final bool loading;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;
  final Future<void> Function() onRefresh;

  Color _statusColor() {
    switch (status) {
      case RealtimeStatus.connected:
        return Colors.green;
      case RealtimeStatus.reconnecting:
      case RealtimeStatus.connecting:
        return Colors.orange;
      case RealtimeStatus.error:
        return Colors.red;
      case RealtimeStatus.disconnected:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (status) {
      case RealtimeStatus.connected:
        return 'Connected';
      case RealtimeStatus.connecting:
        return 'Connecting';
      case RealtimeStatus.reconnecting:
        return 'Reconnecting';
      case RealtimeStatus.error:
        return 'Error';
      case RealtimeStatus.disconnected:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: _statusColor()),
                const SizedBox(width: 8),
                Text(
                  'Realtime: ${_statusLabel()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Unread chat: $unreadChatCount')),
                Chip(
                  label: Text('Unread notifications: $unreadNotificationCount'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: onConnect,
                  child: const Text('Connect'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDisconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({
    required this.state,
    required this.onOpenConversation,
    required this.onMarkConversationRead,
    required this.messageController,
    required this.sending,
    required this.onSend,
  });

  final ChatNotificationState state;
  final Future<void> Function(String conversationId) onOpenConversation;
  final Future<void> Function(String conversationId, {bool silent})
  onMarkConversationRead;
  final TextEditingController messageController;
  final bool sending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: state.conversations.isEmpty
              ? const Center(child: Text('No conversations found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    final conversationId = conversation['id']?.toString() ?? '';
                    final unreadCount = _toInt(conversation['unreadCount']);
                    final isActive =
                        conversationId == state.activeConversationId;

                    return Card(
                      child: ListTile(
                        selected: isActive,
                        title: Text(_conversationTitle(conversation)),
                        subtitle: Text(
                          _messagePreview(conversation),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: unreadCount > 0
                            ? CircleAvatar(
                                radius: 12,
                                child: Text(
                                  unreadCount > 99
                                      ? '99+'
                                      : unreadCount.toString(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )
                            : null,
                        onTap: conversationId.isEmpty
                            ? null
                            : () => onOpenConversation(conversationId),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 4,
          child: state.activeConversationId == null
              ? const Center(
                  child: Text('Select a conversation to view messages.'),
                )
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => onMarkConversationRead(
                          state.activeConversationId!,
                          silent: false,
                        ),
                        icon: const Icon(Icons.mark_chat_read),
                        label: const Text('Mark read'),
                      ),
                    ),
                    Expanded(
                      child: state.messages.isEmpty
                          ? const Center(child: Text('No messages yet.'))
                          : ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              itemCount: state.messages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    state.messages[state.messages.length -
                                        1 -
                                        index];
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message['senderName']?.toString() ??
                                                message['senderId']
                                                    ?.toString() ??
                                                'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            message['content']?.toString() ??
                                                '',
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(
                                              message['sentAt']?.toString(),
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              minLines: 1,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Type message',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: sending ? null : onSend,
                            child: Text(sending ? 'Sending...' : 'Send'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _conversationTitle(Map<String, dynamic> conversation) {
    final title = conversation['title']?.toString();
    if (title != null && title.trim().isNotEmpty) {
      return title;
    }

    final participantsRaw = conversation['participants'];
    if (participantsRaw is List && participantsRaw.isNotEmpty) {
      final names = participantsRaw
          .whereType<Map>()
          .map((participant) => participant['userName']?.toString())
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false);
      if (names.isNotEmpty) {
        return names.join(', ');
      }
    }

    return conversation['id']?.toString() ?? 'Conversation';
  }

  String _messagePreview(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'];
    if (lastMessage is Map) {
      final content = lastMessage['content']?.toString();
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }
    return 'No message';
  }
}

class _NotificationTab extends StatelessWidget {
  const _NotificationTab({
    required this.state,
    required this.onMarkRead,
    required this.onMarkAllRead,
  });

  final ChatNotificationState state;
  final Future<void> Function(String notificationId) onMarkRead;
  final Future<void> Function() onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: state.notifications.isEmpty ? null : onMarkAllRead,
            icon: const Icon(Icons.done_all),
            label: const Text('Mark all read'),
          ),
        ),
        Expanded(
          child: state.notifications.isEmpty
              ? const Center(child: Text('No notifications.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    final notificationId = notification['id']?.toString() ?? '';
                    final isRead = notification['isRead'] == true;

                    return Card(
                      color: isRead ? null : Colors.blue.shade50,
                      child: ListTile(
                        title: Text(
                          notification['title']?.toString() ?? 'Notification',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((notification['content']?.toString() ?? '')
                                .trim()
                                .isNotEmpty)
                              Text(notification['content']?.toString() ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(
                                notification['createdAt']?.toString(),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: isRead
                            ? const Icon(Icons.done, color: Colors.green)
                            : TextButton(
                                onPressed: notificationId.isEmpty
                                    ? null
                                    : () => onMarkRead(notificationId),
                                child: const Text('Mark read'),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

int _toInt(dynamic raw) {
  if (raw is int) {
    return raw;
  }
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

String _formatDateTime(String? raw) {
  final parsed = DateTime.tryParse(raw ?? '');
  if (parsed == null) {
    return '-';
  }
  return parsed.toLocal().toString();
}
