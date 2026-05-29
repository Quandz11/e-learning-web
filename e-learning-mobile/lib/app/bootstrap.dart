import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_flavor.dart';
import '../core/config/env_loader.dart';
import '../core/i18n/app_i18n_controller.dart';
import '../core/telemetry/app_logger.dart';

Future<ProviderContainer> bootstrap() async {
  const flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');
  final appFlavor = AppFlavorX.fromValue(flavor);

  final env = await EnvLoader.load(appFlavor);
  final container = ProviderContainer(
    overrides: [
      appFlavorProvider.overrideWithValue(appFlavor),
      appEnvProvider.overrideWithValue(env),
    ],
  );

  final logger = container.read(appLoggerProvider);
  logger.info('Bootstrapping app with flavor: ${appFlavor.value}');

  await container.read(appI18nControllerProvider.notifier).load();

  return container;
}
