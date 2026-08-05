import 'package:e_learning_mobile/core/session/app_session.dart';

abstract class SessionStorage {
  Future<AppSession?> read();

  Future<void> write(AppSession session);

  Future<void> clear();
}
