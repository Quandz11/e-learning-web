import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/config/app_config_loader.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/foundation/presentation/startup_screen.dart';
import 'package:e_learning_mobile/features/foundation/presentation/startup_failure_screen.dart';
import 'package:e_learning_mobile/core/notifications/local_notification_service.dart';
import 'package:e_learning_mobile/features/notifications/services/notification_service.dart';
import 'package:e_learning_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:e_learning_mobile/shared/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hasSeenOnboardingProvider = StateProvider<bool>((ref) => true);

typedef AppRunner = void Function(Widget app);
typedef Bootstrapper = Future<ProviderContainer> Function();

Future<void> bootstrapAndRun({
  AppRunner runner = runApp,
  Bootstrapper? bootstrapper,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Exception: ${details.exception}\n${details.stack}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    final stack = details.stack;
    String stackInfo = '';
    if (stack != null) {
      final lines = stack.toString().split('\n');
      final appLines = lines.where((l) => l.contains('package:e_learning_mobile')).take(3).toList();
      stackInfo = appLines.isNotEmpty ? '\n${appLines.join('\n')}' : '\n${lines.take(2).join('\n')}';
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFC0392B), size: 32),
              const SizedBox(height: 8),
              SelectableText(
                'Lỗi: ${details.exception}$stackInfo',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC0392B), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runner(_BootstrapHost(bootstrapper: bootstrapper ?? bootstrap));
}

Future<ProviderContainer> bootstrap() async {
  // Run Firebase init in parallel with config loading — both are independent
  final firebaseFuture = Firebase.initializeApp().then((_) async {
    await NotificationService.instance.initialize();
    await NotificationService.instance.setupFirebaseMessaging();
    await LocalNotificationService.instance.initialize();
  }).catchError((Object e) {
    debugPrint('Firebase/Notification init warning (safe to ignore in test/offline): $e');
  });

  final (config, seenOnboarding) = await (
    AppConfigLoader.load(),
    hasSeenOnboarding(),
  ).wait;

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      hasSeenOnboardingProvider.overrideWithValue(seenOnboarding),
    ],
  );

  // Restore session and let Firebase finish concurrently
  await Future.wait([
    container.read(sessionControllerProvider.notifier).restore(),
    firebaseFuture,
  ]);

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
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
