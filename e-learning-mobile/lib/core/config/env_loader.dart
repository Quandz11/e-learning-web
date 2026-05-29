import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_env.dart';
import 'app_flavor.dart';

class EnvLoader {
  static Future<AppEnv> load(AppFlavor flavor) async {
    final filePath = switch (flavor) {
      AppFlavor.dev => 'assets/env/.env.dev',
      AppFlavor.staging => 'assets/env/.env.staging',
      AppFlavor.prod => 'assets/env/.env.prod',
    };

    await dotenv.load(fileName: filePath);

    return AppEnv(
      apiBaseUrl: dotenv.get(
        'API_BASE_URL',
        fallback: 'https://localhost:7145/api',
      ),
      flavor: dotenv.get('APP_FLAVOR', fallback: flavor.value),
      paymentReturnUrl: dotenv.get('PAYMENT_RETURN_URL', fallback: ''),
      paymentCancelUrl: dotenv.get('PAYMENT_CANCEL_URL', fallback: ''),
    );
  }
}

final appEnvProvider = Provider<AppEnv>(
  (_) => const AppEnv(
    apiBaseUrl: 'https://localhost:7145/api',
    flavor: 'dev',
    paymentReturnUrl: '',
    paymentCancelUrl: '',
  ),
);
