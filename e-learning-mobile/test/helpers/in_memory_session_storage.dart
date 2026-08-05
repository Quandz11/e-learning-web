import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/storage/session_storage.dart';

class InMemorySessionStorage implements SessionStorage {
  AppSession? storedSession;

  @override
  Future<void> clear() async {
    storedSession = null;
  }

  @override
  Future<AppSession?> read() async {
    return storedSession;
  }

  @override
  Future<void> write(AppSession session) async {
    storedSession = session;
  }
}
