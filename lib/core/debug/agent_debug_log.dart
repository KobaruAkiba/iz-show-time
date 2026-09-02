import 'package:dio/dio.dart';

/// Debug-mode NDJSON logger for agent instrumentation.
class AgentDebugLog {
  static const _endpoint =
      'http://127.0.0.1:7515/ingest/d0df2c8a-dcfc-4c8f-9799-57a39248eee3';
  static const _sessionId = 'c864a2';

  static void log({
    required String location,
    required String message,
    required String hypothesisId,
    Map<String, dynamic>? data,
    String runId = 'pre-fix',
  }) {
    // #region agent log
    Dio()
        .post(
          _endpoint,
          data: {
            'sessionId': _sessionId,
            'location': location,
            'message': message,
            'hypothesisId': hypothesisId,
            'data': data ?? {},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'runId': runId,
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': _sessionId,
            },
          ),
        )
        .catchError((_) {});
    // #endregion
  }
}
