import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/network/dio_client.dart';

/// Answers each request with the next scripted response, in order.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._responses);

  final List<ResponseBody Function()> _responses;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _responses[requestCount++]();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200, String? retryAfter}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      if (retryAfter != null) 'retry-after': [retryAfter],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  _ScriptedAdapter script(List<ResponseBody Function()> responses) {
    final adapter = _ScriptedAdapter(responses);
    DioClient.httpClientAdapter = adapter;
    return adapter;
  }

  Future<ApiResult<Map<String, dynamic>>> get() =>
      DioClient.instance.get<Map<String, dynamic>>('tv/1');

  group('DioClient.get', () {
    test('returns the decoded body on 200', () async {
      script([() => _json({'id': 1})]);

      final result = await get();

      expect(result.isSuccess, isTrue);
      expect(result.data, {'id': 1});
    });

    test('retries after a 429 and then succeeds', () async {
      final adapter = script([
        () => _json({'status_code': 25}, status: 429, retryAfter: '0'),
        () => _json({'id': 1}),
      ]);

      final result = await get();

      expect(result.isSuccess, isTrue);
      expect(adapter.requestCount, 2);
    });

    test('maps HTTP errors to an error type', () async {
      script([() => _json({'status_code': 34}, status: 404)]);

      final result = await get();

      expect(result.isSuccess, isFalse);
      expect(result.error, ApiErrorType.notFound);
    });

    test('reports an unexpected payload shape as an invalid response',
        () async {
      script([() => _json([1, 2, 3])]);

      final result = await get();

      expect(result.isSuccess, isFalse);
      expect(result.error, ApiErrorType.invalidResponse);
    });

    test('reports a failed connection as a network error', () async {
      script([
        () => throw DioException.connectionError(
              requestOptions: RequestOptions(path: 'tv/1'),
              reason: 'offline',
            ),
      ]);

      final result = await get();

      expect(result.isSuccess, isFalse);
      expect(result.error, ApiErrorType.networkError);
    });
  });
}
