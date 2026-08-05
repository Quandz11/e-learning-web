import 'dart:convert';

import 'package:dio/dio.dart';

class QueuedDioAdapter implements HttpClientAdapter {
  final Map<String, List<_QueuedResponse>> _responses =
      <String, List<_QueuedResponse>>{};
  final List<CapturedRequest> requests = <CapturedRequest>[];

  void enqueue({
    required String method,
    required String path,
    required int statusCode,
    Object? body,
  }) {
    final key = _key(method, path);
    final queue = _responses.putIfAbsent(key, () => <_QueuedResponse>[]);
    queue.add(_QueuedResponse(statusCode: statusCode, body: body));
  }

  CapturedRequest lastRequest(String method, String path) {
    return requests.lastWhere((request) {
      return request.method == method.toUpperCase() && request.path == path;
    });
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      CapturedRequest(
        method: options.method.toUpperCase(),
        path: options.path,
        body: options.data,
        headers: Map<String, dynamic>.from(options.headers),
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
      ),
    );

    final key = _key(options.method, options.path);
    final queue = _responses[key];
    if (queue == null || queue.isEmpty) {
      throw StateError('No queued response for $key');
    }

    final next = queue.removeAt(0);
    final body = next.body;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      next.statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  String _key(String method, String path) => '${method.toUpperCase()} $path';
}

class CapturedRequest {
  const CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
    required this.headers,
    required this.queryParameters,
  });

  final String method;
  final String path;
  final Object? body;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> queryParameters;
}

class _QueuedResponse {
  const _QueuedResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Object? body;
}
