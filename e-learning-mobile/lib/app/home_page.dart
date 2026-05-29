import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/route_paths.dart';
import '../features/chat_notification/presentation/controllers/chat_notification_controller.dart';
import '../shared/widgets/app_scaffold.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatNotificationState = ref.watch(chatNotificationControllerProvider);
    final realtimeUnread =
        chatNotificationState.unreadChatCount +
        chatNotificationState.unreadNotificationCount;

    return AppScaffold(
      title: 'SKVI Mobile',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ModuleTile(title: 'Courses', route: RoutePaths.courses),
          const _ModuleTile(title: 'My courses', route: RoutePaths.myCourses),
          const _ModuleTile(title: 'Checkout', route: RoutePaths.checkout),
          const _ModuleTile(title: 'Orders', route: RoutePaths.orders),
          const _ModuleTile(title: 'Forum', route: RoutePaths.forum),
          const _ModuleTile(title: 'Referral', route: RoutePaths.referral),
          const _ModuleTile(
            title: 'Wellness + AI',
            route: RoutePaths.wellnessAi,
          ),
          _ModuleTile(
            title: 'Chat + Notification',
            route: RoutePaths.chatNotification,
            badgeCount: realtimeUnread,
          ),
          const _ModuleTile(title: 'Profile', route: RoutePaths.profile),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.route,
    this.badgeCount = 0,
  });

  final String title;
  final String route;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final shouldShowBadge = badgeCount > 0;
    final badgeLabel = badgeCount > 99 ? '99+' : badgeCount.toString();

    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shouldShowBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push(route),
      ),
    );
  }
}
