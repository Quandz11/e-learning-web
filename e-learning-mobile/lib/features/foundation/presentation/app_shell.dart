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
      route: AppRoutes.appChat,
      label: 'Tư vấn',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      isCenterAction: true,
    ),
    _ShellDestination(
      route: AppRoutes.appPersonalization,
      label: 'Lối sống',
      icon: Icons.spa_outlined,
      selectedIcon: Icons.spa_rounded,
    ),
    _ShellDestination(
      route: AppRoutes.appProfile,
      label: 'Hồ sơ',
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
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFEAEFE9),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  key: navigationBarKey,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_destinations.length, (index) {
                    final dest = _destinations[index];
                    final isSelected = index == currentIndex;

                    if (dest.isCenterAction) {
                      return _CenterNavButton(
                        destination: dest,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final target = dest.route;
                          if (target != AppRoutes.shellDestinationForLocation(currentLocation)) {
                            context.go(target);
                          }
                        },
                      );
                    }

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final target = dest.route;
                          if (target != AppRoutes.shellDestinationForLocation(currentLocation)) {
                            context.go(target);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEBF5EE)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isSelected ? dest.selectedIcon : dest.icon,
                                  size: 22,
                                  color: isSelected
                                      ? const Color(0xFF0F5B38)
                                      : const Color(0xFF8E9E94),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dest.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF0F5B38)
                                      : const Color(0xFF8E9E94),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  const _CenterNavButton({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF0F5B38), Color(0xFF1B7A4E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F5B38)
                      : const Color(0xFFD4E8DC),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF0F5B38).withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isSelected
                      ? destination.selectedIcon
                      : destination.icon,
                  color: isSelected ? Colors.white : const Color(0xFF0F5B38),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F5B38)
                    : const Color(0xFF717873),
                letterSpacing: -0.2,
              ),
            ),
          ],
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
    this.isCenterAction = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isCenterAction;
}
