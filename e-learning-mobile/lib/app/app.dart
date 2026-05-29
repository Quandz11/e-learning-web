import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_i18n_controller.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import 'realtime_sync_scope.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appI18nControllerProvider).locale;

    return RealtimeSyncScope(
      child: MaterialApp.router(
        title: 'SKVI Learning',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        locale: locale,
      ),
    );
  }
}
