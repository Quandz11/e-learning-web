import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/models/auth_requests.dart';
import '../telemetry/app_logger.dart';
import 'session_state.dart';
import 'token_store.dart';
import 'user_session.dart';

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
      return SessionController(
        authRepository: ref.read(authRepositoryProvider),
        tokenStore: ref.read(tokenStoreProvider),
        logger: ref.read(appLoggerProvider),
      )..restoreSession();
    });

class SessionController extends StateNotifier<SessionState> {
  SessionController({
    required this.authRepository,
    required this.tokenStore,
    required this.logger,
  }) : super(const SessionState.initial());

  final AuthRepository authRepository;
  final TokenStore tokenStore;
  final AppLogger logger;

  UserSession? get sessionOrNull =>
      state.maybeWhen(authenticated: (session) => session, orElse: () => null);

  Future<void> restoreSession() async {
    state = const SessionState.loading();
    try {
      final tokens = await tokenStore.read();
      if (tokens == null) {
        state = const SessionState.unauthenticated();
        return;
      }

      if (tokens.expiresAt.isBefore(DateTime.now())) {
        final refreshed = await authRepository.refresh(tokens.refreshToken);
        final user = authRepository.decodeUserFromJwt(refreshed.accessToken);
        final session = authRepository.buildSession(
          refreshed,
          user,
          fallbackRefreshToken: tokens.refreshToken,
        );
        await tokenStore.save(session.tokens);
        state = SessionState.authenticated(session);
        return;
      }

      final user = authRepository.decodeUserFromJwt(tokens.accessToken);
      state = SessionState.authenticated(
        UserSession(user: user, tokens: tokens),
      );
    } catch (error, stackTrace) {
      logger.error('Failed to restore session', error, stackTrace);
      await tokenStore.clear();
      state = const SessionState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const SessionState.loading();
    try {
      final auth = await authRepository.login(
        LoginRequestModel(email: email, password: password),
      );
      final user = await authRepository.getProfile();
      final session = authRepository.buildSession(auth, user);

      await tokenStore.save(session.tokens);
      state = SessionState.authenticated(session);
    } catch (error, stackTrace) {
      logger.error('Login failed', error, stackTrace);
      state = const SessionState.unauthenticated();
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? referralCode,
  }) async {
    await authRepository.register(
      RegisterRequestModel(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        referralCode: referralCode,
      ),
    );
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    state = const SessionState.loading();
    try {
      final auth = await authRepository.verifyOtp(email, otp);
      final user = await authRepository.getProfile();
      final session = authRepository.buildSession(auth, user);
      await tokenStore.save(session.tokens);
      state = SessionState.authenticated(session);
    } catch (error, stackTrace) {
      logger.error('Verify OTP failed', error, stackTrace);
      state = const SessionState.unauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    final session = sessionOrNull;
    if (session != null) {
      try {
        await authRepository.logout(session.tokens.refreshToken);
      } catch (_) {}
    }

    await tokenStore.clear();
    state = const SessionState.unauthenticated();
  }
}
