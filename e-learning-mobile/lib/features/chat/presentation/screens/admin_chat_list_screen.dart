import 'package:e_learning_mobile/features/chat/data/models/chat_models.dart';
import 'package:e_learning_mobile/features/chat/presentation/controllers/admin_chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminChatListScreen extends ConsumerStatefulWidget {
  const AdminChatListScreen({
    super.key,
    required this.onSelectConversation,
    this.onBack,
  });

  final Function(AdminConversationItem item) onSelectConversation;
  final VoidCallback? onBack;

  @override
  ConsumerState<AdminChatListScreen> createState() =>
      _AdminChatListScreenState();
}

class _AdminChatListScreenState extends ConsumerState<AdminChatListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminChatListControllerProvider);
    final notifier = ref.read(adminChatListControllerProvider.notifier);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Hỗ trợ & Trò chuyện',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? colorScheme.primary : const Color(0xFF0F5B38),
            ),
            tooltip: 'Làm mới',
            onPressed: () => notifier.load(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF0F4F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => notifier.setSearchQuery(val),
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm cuộc trò chuyện...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? colorScheme.onSurfaceVariant
                        : const Color(0xFF8A938C),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? colorScheme.onSurfaceVariant
                        : const Color(0xFF717873),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: isDark
                                ? colorScheme.onSurfaceVariant
                                : const Color(0xFF717873),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Tabs: Authenticated vs Guest
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerLow
                  : const Color(0xFFEBF2EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label:
                        'Thành viên (${state.authenticatedConversations.length})',
                    isActive: state.activeTab == 'authenticated',
                    onTap: () => notifier.setActiveTab('authenticated'),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Khách (${state.guestConversations.length})',
                    isActive: state.activeTab == 'guest',
                    onTap: () => notifier.setActiveTab('guest'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Conversation List
          Expanded(
            child: state.isLoading && state.filteredConversations.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F5B38),
                      ),
                    ),
                  )
                : state.error != null && state.filteredConversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: isDark
                              ? colorScheme.onSurfaceVariant
                              : const Color(0xFFA5A9A5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không thể tải danh sách cuộc trò chuyện',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => notifier.load(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : state.filteredConversations.isEmpty
                ? RefreshIndicator(
                    color: const Color(0xFF0F5B38),
                    onRefresh: () => notifier.load(),
                    child: ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? colorScheme.onSurfaceVariant
                                  : const Color(0xFF8A938C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF0F5B38),
                    onRefresh: () => notifier.load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: state.filteredConversations.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark
                            ? colorScheme.outlineVariant
                            : const Color(0xFFEFF3F0),
                      ),
                      itemBuilder: (context, index) {
                        final item = state.filteredConversations[index];
                        return _ConversationTile(
                          item: item,
                          onTap: () => widget.onSelectConversation(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final activeBg = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;
    final activeText = isDark
        ? colorScheme.onPrimaryContainer
        : const Color(0xFF0F5B38);
    final inactiveText = isDark
        ? colorScheme.onSurfaceVariant
        : const Color(0xFF717873);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? activeText : inactiveText,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.onTap});

  final AdminConversationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasUnread = item.unreadCount > 0;
    final timeStr = _formatTime(item.lastActivity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.type == 'guest'
                        ? (isDark
                              ? const Color(0xFF3B1E54)
                              : const Color(0xFFF3E8FF))
                        : (isDark
                              ? const Color(0xFF163829)
                              : const Color(0xFFEBF5EE)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.type == 'guest'
                          ? (isDark
                                ? const Color(0xFF6B21A8)
                                : const Color(0xFFD8B4FE))
                          : (isDark
                                ? const Color(0xFF2E6F4E)
                                : const Color(0xFFD4E8DC)),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      item.type == 'guest'
                          ? Icons.person_outline_rounded
                          : Icons.person_rounded,
                      color: item.type == 'guest'
                          ? (isDark
                                ? const Color(0xFFC084FC)
                                : const Color(0xFF7E22CE))
                          : (isDark
                                ? colorScheme.onPrimaryContainer
                                : const Color(0xFF0F5B38)),
                      size: 24,
                    ),
                  ),
                ),
                if (item.isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? colorScheme.surface : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // User Info & Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: hasUnread
                                ? (isDark
                                      ? colorScheme.onPrimaryContainer
                                      : const Color(0xFF0F5B38))
                                : (isDark
                                      ? colorScheme.onSurfaceVariant
                                      : const Color(0xFF8A938C)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.lastMessage ?? 'Bắt đầu cuộc trò chuyện',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: hasUnread
                                ? colorScheme.onSurface
                                : (isDark
                                      ? colorScheme.onSurfaceVariant
                                      : const Color(0xFF717873)),
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5B38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.unreadCount > 99
                                ? '99+'
                                : '${item.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final local = dt.toLocal();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('dd/MM').format(local);
  }
}
