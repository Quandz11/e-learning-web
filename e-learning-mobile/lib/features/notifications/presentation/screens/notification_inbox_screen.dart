import 'package:e_learning_mobile/features/notifications/data/models/notification_item.dart';
import 'package:e_learning_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app');
            }
          },
        ),
        title: Text(
          'Thông báo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllAsRead();
            },
            child: const Text(
              'Đã đọc tất cả',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F5B38),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5B38)),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Color(0xFFA5A9A5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không thể tải thông báo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E2621),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF717873),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .load(forceRefresh: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F5B38),
                    side: const BorderSide(color: Color(0xFF0F5B38)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (payload) {
          if (payload.notifications.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFF0F5B38),
              onRefresh: () => ref
                  .read(notificationsControllerProvider.notifier)
                  .load(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5EE),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 36,
                            color: Color(0xFF0F5B38),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Hộp thư thông báo trống',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2621),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bạn sẽ nhận được thông báo về lộ trình học,\nnhắc nhở thói quen và tin tức mới nhất tại đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF717873),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

          return RefreshIndicator(
            color: const Color(0xFF0F5B38),
            onRefresh: () => ref
                .read(notificationsControllerProvider.notifier)
                .load(forceRefresh: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: payload.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = payload.notifications[index];
                return _NotificationCard(
                  item: item,
                  dateFormat: dateFormat,
                  onTap: () {
                    if (!item.isRead) {
                      ref
                          .read(notificationsControllerProvider.notifier)
                          .markAsRead(item.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.dateFormat,
    required this.onTap,
  });

  final NotificationItem item;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final unreadBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFF4F9F5);
    final readBg = isDark ? colorScheme.surfaceContainerLow : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead ? readBg : unreadBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? (isDark
                        ? colorScheme.outlineVariant
                        : const Color(0xFFE9EBEA))
                  : (isDark
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : const Color(0xFFD4E8DC)),
              width: 1,
            ),
            boxShadow: [
              if (!item.isRead && !isDark)
                BoxShadow(
                  color: const Color(0xFF0F5B38).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isRead
                      ? (isDark
                            ? colorScheme.surfaceContainerLowest
                            : const Color(0xFFF1F3F2))
                      : colorScheme.primary.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_rounded,
                  size: 20,
                  color: item.isRead
                      ? (isDark
                            ? colorScheme.onSurfaceVariant
                            : const Color(0xFF717873))
                      : (isDark
                            ? colorScheme.onPrimaryContainer
                            : const Color(0xFF0F5B38)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F5B38),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.content != null && item.content!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.content!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF4C544F),
                          height: 1.4,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(item.createdAt.toLocal()),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFFA5A9A5),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
