import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/shared/theme/app_radius.dart';
import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:e_learning_mobile/shared/theme/app_spacing.dart';
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
      label: 'Học tập',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
    ),
    _ShellDestination(
      route: AppRoutes.appCommunity,
      label: 'Cộng đồng',
      icon: Icons.groups_2_outlined,
      selectedIcon: Icons.groups_2_rounded,
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
    final navSurfaceColor = colorScheme.surfaceContainerLow;
    final navBorderColor = colorScheme.outlineVariant;
    final indicatorColor = colorScheme.secondaryContainer;
    final selectedForeground = colorScheme.onSecondaryContainer;
    final unselectedForeground = colorScheme.onSurfaceVariant;

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
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 72,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                indicatorColor: indicatorColor,
                indicatorShape: const StadiumBorder(),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: AppSizes.iconMd,
                    color: isSelected
                        ? selectedForeground
                        : unselectedForeground,
                  );
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? selectedForeground
                        : unselectedForeground,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  );
                }),
              ),
              child: Material(
                elevation: 3,
                color: navSurfaceColor,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: navBorderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
