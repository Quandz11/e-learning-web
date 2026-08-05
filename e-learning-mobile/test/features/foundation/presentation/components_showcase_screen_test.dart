import 'package:e_learning_mobile/app/app.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/routing/app_router.dart';
import 'package:e_learning_mobile/core/routing/deep_link_config.dart';
import 'package:e_learning_mobile/core/storage/secure_session_storage.dart';
import 'package:e_learning_mobile/features/foundation/presentation/components_showcase_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_session_storage.dart';

void main() {
  testWidgets('component showcase route resolves in debug builds', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
        ),
        sessionStorageProvider.overrideWithValue(InMemorySessionStorage()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pump();

    container.read(appRouterProvider).go(AppRoutes.devComponents);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ComponentsShowcaseScreen), findsOneWidget);
    expect(find.text('Design foundation'), findsOneWidget);
  });
}
