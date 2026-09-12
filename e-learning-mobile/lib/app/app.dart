import 'dart:async';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/features/notifications/services/notification_service.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:e_learning_mobile/shared/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<NotificationTapEvent>? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    _notificationTapSub =
        NotificationService.instance.onNotificationTapStream.listen(_handleNotificationTap);
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    super.dispose();
  }

  void _handleNotificationTap(NotificationTapEvent event) {
    debugPrint('🔥 Handling Notification Tap: type=${event.type}, route=${event.targetRoute}, convId=${event.conversationId}');
    final router = ref.read(appRouterProvider);

    if (event.type == 'chat') {
      if (event.conversationId != null && event.conversationId!.isNotEmpty) {
        router.go('${AppRoutes.appChat}?conversationId=${event.conversationId}');
      } else {
        router.go(AppRoutes.appChat);
      }
    } else if (event.targetRoute != null && event.targetRoute!.isNotEmpty) {
      router.go(event.targetRoute!);
    } else {
      router.go(AppRoutes.appNotifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Nhịn Ăn Chữa Lành',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
    );
  }
}
