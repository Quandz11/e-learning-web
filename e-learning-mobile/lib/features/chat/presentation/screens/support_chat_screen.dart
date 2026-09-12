import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:e_learning_mobile/features/chat/presentation/controllers/admin_chat_controller.dart';
import 'package:e_learning_mobile/features/chat/presentation/controllers/admin_chat_detail_controller.dart';
import 'package:e_learning_mobile/features/chat/presentation/controllers/chat_controller.dart';
import 'package:e_learning_mobile/features/chat/presentation/screens/admin_chat_list_screen.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  AdminConversationItem? _selectedConversation;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).profile;
    final role = profile?.role.toUpperCase() ?? '';
    final isAdmin = role == 'ADMIN' ||
        role == 'CARE' ||
        role == 'STAFF' ||
        role.contains('ADMIN') ||
        role.contains('CARE');

    final uri = GoRouterState.of(context).uri;
    final queryConvId = uri.queryParameters['conversationId'];
    if (isAdmin && queryConvId != null && queryConvId.isNotEmpty && _selectedConversation == null) {
      final adminListState = ref.watch(adminChatListControllerProvider);
      final found = [...adminListState.authenticatedConversations, ...adminListState.guestConversations]
          .firstWhere((c) => c.id == queryConvId || c.guestId == queryConvId,
              orElse: () => AdminConversationItem(
                id: queryConvId,
                type: 'authenticated',
                userName: 'Cuộc trò chuyện',
                unreadCount: 0,
                isActive: true,
              ));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedConversation == null) {
          setState(() {
            _selectedConversation = found;
          });
        }
      });
    }

    // Admin Mode: List View when no conversation selected
    if (isAdmin && _selectedConversation == null) {
      return AdminChatListScreen(
        onSelectConversation: (item) {
          setState(() {
            _selectedConversation = item;
          });
        },
        onBack: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/app');
          }
        },
      );
    }

    // Admin Chat Detail View
    if (isAdmin && _selectedConversation != null) {
      final detailItem = _selectedConversation!;
      final state = ref.watch(adminChatDetailProvider(detailItem));
      final notifier = ref.read(adminChatDetailProvider(detailItem).notifier);

      ref.listen(adminChatDetailProvider(detailItem), (_, next) {
        _scrollToBottom();
      });

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final colorScheme = Theme.of(context).colorScheme;

      return Scaffold(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
        appBar: AppBar(
          backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? colorScheme.onSurface : const Color(0xFF1E2621)),
            onPressed: () {
              setState(() {
                _selectedConversation = null;
              });
            },
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: detailItem.type == 'guest' ? const Color(0xFFF3E8FF) : const Color(0xFFEBF5EE),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: detailItem.type == 'guest' ? const Color(0xFFD8B4FE) : const Color(0xFFD4E8DC),
                    width: 1,
                  ),
                ),
                child: Icon(
                  detailItem.type == 'guest' ? Icons.person_outline_rounded : Icons.person_rounded,
                  size: 20,
                  color: detailItem.type == 'guest' ? const Color(0xFF7E22CE) : const Color(0xFF0F5B38),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detailItem.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? colorScheme.onSurface : const Color(0xFF1E2621),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      detailItem.type == 'guest' ? 'Khách vãng lai' : 'Học viên chính thức',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: detailItem.type == 'guest' ? const Color(0xFF7E22CE) : const Color(0xFF0F5B38),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: state.isLoading && state.messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5B38)),
                      ),
                    )
                  : state.error != null && state.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFFA5A9A5)),
                              const SizedBox(height: 12),
                              Text(
                                state.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF717873)),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => notifier.load(),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final msg = state.messages[index];
                            return _ChatBubble(message: msg);
                          },
                        ),
            ),
            _buildInputBar(
              isSending: state.isSending,
              onSend: () async {
                final text = _textController.text;
                if (text.trim().isEmpty) return;
                _textController.clear();
                await notifier.sendMessage(text);
                _scrollToBottom();
              },
            ),
          ],
        ),
      );
    }

    // Student Mode: Direct Single Support Chat
    final state = ref.watch(chatControllerProvider);

    ref.listen(chatControllerProvider, (_, next) {
      _scrollToBottom();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFFBFBFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? colorScheme.onSurface : const Color(0xFF1E2621)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF5EE),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4E8DC), width: 1),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 20,
                color: Color(0xFF0F5B38),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ban Cố Vấn Sống Khỏe',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? colorScheme.onSurface : const Color(0xFF1E2621),
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'Trực tuyến • Hỗ trợ học viên',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF0F5B38),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5B38)),
                    ),
                  )
                : state.error != null && state.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFA5A9A5)),
                              const SizedBox(height: 16),
                              Text(
                                state.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF717873),
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => ref.read(chatControllerProvider.notifier).load(),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: state.messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            final colorScheme = Theme.of(context).colorScheme;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainerLow : const Color(0xFFF4F9F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? colorScheme.outlineVariant : const Color(0xFFD4E8DC),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 18,
                                    color: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Bạn đang trò chuyện trực tiếp với Ban Cố Vấn Sống Khỏe SKVI. Mọi thông tin đều được bảo mật tuyệt đối.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                        color: isDark ? colorScheme.onSurface : const Color(0xFF334036),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final msg = state.messages[index - 1];
                          return _ChatBubble(message: msg);
                        },
                      ),
          ),
          _buildInputBar(
            isSending: state.isSending,
            onSend: () async {
              final text = _textController.text;
              if (text.trim().isEmpty) return;
              _textController.clear();
              await ref.read(chatControllerProvider.notifier).sendMessage(text);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar({
    required bool isSending,
    required VoidCallback onSend,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? colorScheme.outlineVariant : const Color(0xFFE9EBEA),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF4F6F5),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? colorScheme.onSurface : const Color(0xFF1E2621),
                ),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Soạn tin nhắn...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFFA5A9A5),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isSending ? null : onSend,
            icon: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF0F5B38),
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('HH:mm').format(message.sentAt.toLocal());

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe
              ? const Color(0xFF0F5B38)
              : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!message.isMe && message.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? colorScheme.onPrimaryContainer : const Color(0xFF0F5B38),
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: message.isMe
                    ? Colors.white
                    : (isDark ? colorScheme.onSurface : const Color(0xFF1E2621)),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: message.isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : (isDark ? colorScheme.onSurfaceVariant : const Color(0xFFA5A9A5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
