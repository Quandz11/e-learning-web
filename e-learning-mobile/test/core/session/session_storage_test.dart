import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_session_storage.dart';

void main() {
  test('write and read session using in-memory fake', () async {
    final storage = InMemorySessionStorage();
    final session = AppSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: DateTime.utc(2026, 7, 29, 12),
    );

    await storage.write(session);

    expect(await storage.read(), isNotNull);
    expect((await storage.read())?.accessToken, 'access');
  });

  test('clear session removes stored values', () async {
    final storage = InMemorySessionStorage()
      ..storedSession = AppSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.utc(2026, 7, 29, 12),
      );

    await storage.clear();

    expect(await storage.read(), isNull);
  });
}
