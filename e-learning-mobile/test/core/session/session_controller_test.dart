import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_session_storage.dart';

void main() {
  group('SessionController', () {
    late InMemorySessionStorage storage;

    SessionRepository buildRepository({required Dio dio}) {
      return SessionRepository(
        storage: storage,
        config: AppConfig(
          apiBaseUrl: Uri.parse('https://api.example.com/api'),
          flavor: AppFlavor.dev,
          paymentReturnUrl: Uri.parse('skvi://payment/result'),
          paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
        ),
        refreshDio: dio,
      );
    }

    setUp(() {
      storage = InMemorySessionStorage();
    });

    test('restore authenticated session', () async {
      storage.storedSession = AppSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final controller = SessionController(buildRepository(dio: Dio()));

      await controller.restore();

      expect(controller.state.status, SessionStatus.authenticated);
    });

    test('restore unauthenticated session', () async {
      final controller = SessionController(buildRepository(dio: Dio()));

      await controller.restore();

      expect(controller.state.status, SessionStatus.unauthenticated);
    });

    test('clear session', () async {
      final controller = SessionController(buildRepository(dio: Dio()));
      await controller.setSession(
        AppSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );

      await controller.clearSession();

      expect(controller.state.status, SessionStatus.unauthenticated);
      expect(await storage.read(), isNull);
    });

    test('clearSession when unauthenticated does not re-clear', () async {
      final repo = buildRepository(dio: Dio());
      final controller = SessionController(repo);
      await controller.restore(); // resolves unauthenticated
      final initialGen = repo.generation;

      await controller.clearSession();
      expect(repo.generation, initialGen);
    });

    test('expired session refreshes during restore', () async {
      storage.storedSession = AppSession(
        accessToken: 'old',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      final dio = Dio()..httpClientAdapter = _RefreshAdapter();
      final controller = SessionController(buildRepository(dio: dio));

      await controller.restore();

      expect(controller.state.status, SessionStatus.authenticated);
      expect(controller.state.session?.accessToken, 'new-access');
    });

    test(
      'failed refresh resolves unauthenticated and clears session',
      () async {
        storage.storedSession = AppSession(
          accessToken: 'old',
          refreshToken: 'refresh',
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 1),
          ),
        );
        final dio = Dio()..httpClientAdapter = _UnauthorizedAdapter();
        final controller = SessionController(buildRepository(dio: dio));

        await controller.restore();

        expect(controller.state.status, SessionStatus.unauthenticated);
        expect(await storage.read(), isNull);
      },
    );

    test('malformed refresh response resolves unauthenticated', () async {
      storage.storedSession = AppSession(
        accessToken: 'old',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      final dio = Dio()..httpClientAdapter = _MalformedRefreshAdapter();
      final controller = SessionController(buildRepository(dio: dio));

      await controller.restore();

      expect(controller.state.status, SessionStatus.unauthenticated);
      expect(await storage.read(), isNull);
    });

    test('secure-storage read failure resolves unauthenticated', () async {
      final controller = SessionController(
        SessionRepository(
          storage: _ThrowingStorage(),
          config: AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
          refreshDio: Dio(),
        ),
      );

      await controller.restore();

      expect(controller.state.status, SessionStatus.unauthenticated);
    });
  });
}

class _RefreshAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"accessToken":"new-access","refreshToken":"new-refresh","expiresAt":"2027-07-30T00:00:00Z"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.badResponse(
      statusCode: 401,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 401,
        data: const {'message': 'Unauthorized'},
      ),
    );
  }
}

class _MalformedRefreshAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"accessToken":"","refreshToken":"","expiresAt":""}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _ThrowingStorage extends InMemorySessionStorage {
  @override
  Future<AppSession?> read() async {
    throw StateError('read failed');
  }
}
