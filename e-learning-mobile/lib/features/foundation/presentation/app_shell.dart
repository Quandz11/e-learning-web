import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  final Widget child;
  final String currentLocation;

  static const navigationBarKey = Key('app_shell_navigation_bar');
  static const navigationSafeAreaKey = Key('app_shell_navigation_safe_area');

  static const _destinations = <_ShellDestination>[
    _ShellDestination(
      route: AppRoutes.appHome,
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _ShellDestination(
      route: AppRoutes.appLearning,
      label: 'Khóa học',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
    ),
    _ShellDestination(
      route: AppRoutes.appPersonalization,
      label: 'Cá nhân hóa',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
    ),
    _ShellDestination(
      route: AppRoutes.appProfile,
      label: 'Cá nhân',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  int get _currentIndex {
    final shellRoute = AppRoutes.shellDestinationForLocation(currentLocation);
    final index = AppRoutes.shellDestinations.indexOf(shellRoute);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final overlayStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
          );


    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope<void>(
        canPop: currentIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && currentIndex != 0) {
            context.go(AppRoutes.appHome);
          }
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: ColoredBox(
            color: colorScheme.surface,
            child: SafeArea(top: false, bottom: false, child: child),
          ),
          bottomNavigationBar: SafeArea(
            key: navigationSafeAreaKey,
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 66,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    indicatorColor: const Color(0xFFD8EAD9),
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: 24,
                        color: isSelected
                            ? const Color(0xFF132A17)
                            : const Color(0xFF757575),
                      );
                    }),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF132A17)
                            : const Color(0xFF757575),
                      );
                    }),
                  ),
                  child: NavigationBar(
                    key: navigationBarKey,
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) {
                      final target = AppRoutes.shellDestinations[index];
                      if (target !=
                          AppRoutes.shellDestinationForLocation(
                            currentLocation,
                          )) {
                        context.go(target);
                      }
                    },
                    destinations: _destinations
                        .map((destination) {
                          return NavigationDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(destination.selectedIcon),
                            label: destination.label,
                            tooltip: destination.label,
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
