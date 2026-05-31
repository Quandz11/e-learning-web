import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chat_notification/presentation/controllers/chat_notification_controller.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Trang chủ'),
    _TabItem(icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Khóa học'),
    _TabItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Diễn đàn'),
    _TabItem(icon: Icons.spa_outlined, activeIcon: Icons.spa_rounded, label: 'Sức Khỏe'),
    _TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Tôi'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatNotificationControllerProvider);
    final totalBadge =
        chatState.unreadChatCount + chatState.unreadNotificationCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            // Badge on Forum tab (index 2)
            final showBadge = i == 2 && totalBadge > 0;
            return NavigationDestination(
              icon: showBadge
                  ? Badge(
                      label: Text(
                        totalBadge > 99 ? '99+' : '$totalBadge',
                      ),
                      child: Icon(tab.icon),
                    )
                  : Icon(tab.icon),
              selectedIcon: showBadge
                  ? Badge(
                      label: Text(
                        totalBadge > 99 ? '99+' : '$totalBadge',
                      ),
                      child: Icon(tab.activeIcon),
                    )
                  : Icon(tab.activeIcon),
              label: tab.label,
            );
          }),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
