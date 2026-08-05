import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/core/network/auth_interceptor.dart';
import 'package:e_learning_mobile/core/session/app_session.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/storage/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySessionStorage storage;
  late FakeAdapter adapter;
  late Dio dio;
  late SessionRepository sessionRepository;
  late SessionController sessionController;

  setUp(() {
    storage = InMemorySessionStorage();
    adapter = FakeAdapter();
    sessionRepository = SessionRepository(
      storage: storage,
      config: AppConfig(
        apiBaseUrl: Uri.parse('https://api.example.com/api'),
        flavor: AppFlavor.dev,
        paymentReturnUrl: Uri.parse('skvi://payment/result'),
        paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
      ),
      refreshDio: Dio()..httpClientAdapter = adapter,
    );
    sessionController = SessionController(sessionRepository);

    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com/api',
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        sessionRepository: sessionRepository,
        sessionController: sessionController,
      ),
    );
  });

  test('bearer token is attached', () async {
    storage.storedSession = _session();
    adapter.queueSuccess('/protected');

    await dio.get('/protected');

    expect(adapter.lastAuthorizationHeader, 'Bearer access');
  });

  test('requests without session omit authorization', () async {
    adapter.queueSuccess('/public');

    await dio.get('/public');

    expect(adapter.lastAuthorizationHeader, isNull);
  });

  test('successful refresh updates storage and retries once', () async {
    storage.storedSession = _session();
    adapter.queueUnauthorizedThenSuccess('/protected');
    adapter.refreshResponse = {
      'accessToken': 'fresh-access',
      'refreshToken': 'fresh-refresh',
      'expiresAt': '2026-07-30T00:00:00Z',
    };

    final response = await dio.get('/protected');

    expect(response.statusCode, 200);
    expect((await storage.read())?.accessToken, 'fresh-access');
    expect(adapter.refreshCallCount, 1);
    expect(adapter.requestCountFor('/protected'), 2);
  });

  test('refresh rejection clears the session', () async {
    storage.storedSession = _session();
    adapter.queueUnauthorizedThenSuccess('/protected');
    adapter.refreshStatusCode = 401;

    await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));

    expect(await storage.read(), isNull);
  });

  test('malformed refresh response clears the session', () async {
    storage.storedSession = _session();
    adapter.queueUnauthorizedThenSuccess('/protected');
    adapter.refreshResponse = {'accessToken': 'only-access'};

    await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));

    expect(await storage.read(), isNull);
  });

  test('authentication endpoints are not recursively refreshed', () async {
    storage.storedSession = _session();
    adapter.queueUnauthorized('/auth/login');

    await expectLater(dio.post('/auth/login'), throwsA(isA<DioException>()));

    expect(adapter.refreshCallCount, 0);
  });

  test('concurrent 401 requests use one refresh operation', () async {
    storage.storedSession = _session();
    adapter.queueUnauthorizedThenSuccess('/protected-a');
    adapter.queueUnauthorizedThenSuccess('/protected-b');
    adapter.refreshResponse = {
      'accessToken': 'fresh-access',
      'refreshToken': 'fresh-refresh',
      'expiresAt': '2026-07-30T00:00:00Z',
    };

    await Future.wait([dio.get('/protected-a'), dio.get('/protected-b')]);

    expect(adapter.refreshCallCount, 1);
  });

  test('failed refresh fails all waiting requests', () async {
    storage.storedSession = _session();
    adapter.queueUnauthorizedThenSuccess('/protected-a');
    adapter.queueUnauthorizedThenSuccess('/protected-b');
    adapter.refreshStatusCode = 401;

    final results = await Future.wait<Object?>([
      dio
          .get('/protected-a')
          .then<Object?>((_) => null)
          .catchError((error) => error),
      dio
          .get('/protected-b')
          .then<Object?>((_) => null)
          .catchError((error) => error),
    ]);

    expect(results.whereType<DioException>().length, 2);
    expect(await storage.read(), isNull);
  });

  test('retry preserves request details', () async {
    storage.storedSession = _session();
    adapter.queueUnauthorizedThenSuccess('/protected');
    adapter.refreshResponse = {
      'accessToken': 'fresh-access',
      'refreshToken': 'fresh-refresh',
      'expiresAt': '2026-07-30T00:00:00Z',
    };

    await dio.post(
      '/protected',
      data: {'hello': 'world'},
      queryParameters: {'page': 1},
      options: Options(headers: {'X-Test': 'true'}),
    );

    expect(adapter.lastMethodFor('/protected'), 'POST');
    expect(adapter.lastQueryFor('/protected'), {'page': 1});
    expect(adapter.lastBodyFor('/protected'), {'hello': 'world'});
    expect(adapter.lastCustomHeaderFor('/protected', 'X-Test'), 'true');
  });
}

class InMemorySessionStorage implements SessionStorage {
  AppSession? storedSession;

  @override
  Future<void> clear() async {
    storedSession = null;
  }

  @override
  Future<AppSession?> read() async => storedSession;

  @override
  Future<void> write(AppSession session) async {
    storedSession = session;
  }
}

AppSession _session() {
  return AppSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2026, 7, 29, 12),
  );
}

class FakeAdapter implements HttpClientAdapter {
  final Map<String, List<int>> _statusQueues = <String, List<int>>{};
  final Map<String, List<Map<String, dynamic>?>> _bodyQueues =
      <String, List<Map<String, dynamic>?>>{};
  final Map<String, int> _requestCounts = <String, int>{};
  final Map<String, String?> _lastMethods = <String, String?>{};
  final Map<String, Map<String, dynamic>?> _lastBodies =
      <String, Map<String, dynamic>?>{};
  final Map<String, Map<String, dynamic>> _lastQueries =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _lastHeaders =
      <String, Map<String, dynamic>>{};

  Map<String, dynamic>? refreshResponse;
  int refreshStatusCode = 200;
  int refreshCallCount = 0;
  String? lastAuthorizationHeader;

  void queueSuccess(String path) {
    _statusQueues[path] = [200];
    _bodyQueues[path] = [
      <String, dynamic>{'ok': true},
    ];
  }

  void queueUnauthorized(String path) {
    _statusQueues[path] = [401];
    _bodyQueues[path] = [null];
  }

  void queueUnauthorizedThenSuccess(String path) {
    _statusQueues[path] = [401, 200];
    _bodyQueues[path] = [
      null,
      <String, dynamic>{'ok': true},
    ];
  }

  int requestCountFor(String path) => _requestCounts[path] ?? 0;

  String? lastMethodFor(String path) => _lastMethods[path];

  Map<String, dynamic>? lastBodyFor(String path) => _lastBodies[path];

  Map<String, dynamic>? lastQueryFor(String path) => _lastQueries[path];

  String? lastCustomHeaderFor(String path, String key) =>
      _lastHeaders[path]?[key]?.toString();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    _requestCounts[path] = (_requestCounts[path] ?? 0) + 1;
    _lastMethods[path] = options.method;
    _lastBodies[path] = options.data is Map<String, dynamic>
        ? Map<String, dynamic>.from(options.data as Map<String, dynamic>)
        : null;
    _lastQueries[path] = Map<String, dynamic>.from(options.queryParameters);
    _lastHeaders[path] = Map<String, dynamic>.from(options.headers);
    lastAuthorizationHeader = options.headers['Authorization']?.toString();

    if (path == '/auth/refresh') {
      refreshCallCount += 1;
      return ResponseBody.fromString(
        jsonEncode(refreshResponse ?? <String, dynamic>{}),
        refreshStatusCode,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    final statuses = _statusQueues[path]!;
    final status = statuses.removeAt(0);
    final bodyQueue = _bodyQueues[path]!;
    final body = bodyQueue.removeAt(0);

    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
