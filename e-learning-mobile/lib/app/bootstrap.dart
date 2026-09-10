import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/config/app_config_loader.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/foundation/presentation/startup_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/startup_failure_screen.dart';
import 'package:e_learning_mobile/features/notifications/services/notification_service.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AppRunner = void Function(Widget app);
typedef Bootstrapper = Future<ProviderContainer> Function();

Future<void> bootstrapAndRun({
  AppRunner runner = runApp,
  Bootstrapper? bootstrapper,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runner(_BootstrapHost(bootstrapper: bootstrapper ?? bootstrap));
}

Future<ProviderContainer> bootstrap() async {
  try {
    await Firebase.initializeApp();
    await NotificationService.instance.initialize();
    await NotificationService.instance.setupFirebaseMessaging();
  } catch (e) {
    debugPrint('Firebase/Notification init warning (safe to ignore in test/offline): $e');
  }

  final config = await AppConfigLoader.load();
  final container = ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(config)],
  );

  await container.read(sessionControllerProvider.notifier).restore();

  return container;
}

class _BootstrapHost extends StatefulWidget {
  const _BootstrapHost({required this.bootstrapper});

  final Bootstrapper bootstrapper;

  @override
  State<_BootstrapHost> createState() => _BootstrapHostState();
}

class _BootstrapHostState extends State<_BootstrapHost> {
  ProviderContainer? _container;
  String? _startupErrorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final container = _container;
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const App(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: _startupErrorMessage == null
          ? const StartupScreen()
          : StartupFailureScreen(message: _startupErrorMessage!),
    );
  }

  Future<void> _start() async {
    try {
      final container = await widget.bootstrapper();
      if (!mounted) {
        container.dispose();
        return;
      }
      setState(() {
        _container = container;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _startupErrorMessage = error is AppConfigException
            ? error.userMessage
            : 'The app could not start. Please try again later.';
      });
    }
  }
}
