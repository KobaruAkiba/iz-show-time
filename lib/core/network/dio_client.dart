import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../../l10n/l10n.dart';
import 'api_error.dart';
import 'network_feedback.dart';

export 'api_error.dart';

/// Outcome of an HTTP call: either [ApiSuccess] or [ApiFailure].
///
/// Sealed so callers switch over both cases; a success carries no error.
sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(T data) = ApiSuccess<T>;

  factory ApiResult.error(ApiErrorType type, {String? message}) =>
      ApiFailure<T>(type, message ?? apiErrorMessage(type));

  bool get isSuccess => this is ApiSuccess<T>;

  T? get data => switch (this) {
        ApiSuccess<T>(:final data) => data,
        ApiFailure<T>() => null,
      };

  ApiErrorType? get error => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(:final error) => error,
      };
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  @override
  final T data;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error, this.message);

  @override
  final ApiErrorType error;

  /// Technical detail for logs; UI copy comes from [apiErrorMessage].
  final String message;
}

/// Main HTTP client for TMDB API
class DioClient {
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._internal();

  final Dio _dio;
  static String _apiKey = '';

  DioClient._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: AppConstants.connectionTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _setupInterceptors();
  }

  void _applyAuth(RequestOptions options) {
    if (_apiKey.isEmpty) return;

    if (_apiKey.startsWith('eyJ')) {
      options.headers['Authorization'] = 'Bearer $_apiKey';
    } else {
      options.queryParameters.putIfAbsent('api_key', () => _apiKey);
    }
  }

  bool _hasJsonBody(dynamic data) {
    if (data == null) return false;
    if (data is String) {
      return data.trim().isNotEmpty && !data.trimLeft().startsWith('<!');
    }
    return true;
  }

  ApiErrorType _errorTypeForStatus(int? statusCode) {
    switch (statusCode) {
      case 401:
      case 403:
        return ApiErrorType.unauthorized;
      case 404:
        return ApiErrorType.notFound;
      case 429:
        return ApiErrorType.rateLimit;
      default:
        return ApiErrorType.invalidResponse;
    }
  }

  ApiErrorType _errorTypeForDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiErrorType.timeout;
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return ApiErrorType.networkError;
      case DioExceptionType.badResponse:
        return _errorTypeForStatus(e.response?.statusCode);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return ApiErrorType.networkError;
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _applyAuth(options);
        if (kDebugMode) {
          // ignore: avoid_print
          print('📡 [REQUEST] ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          // ignore: avoid_print
          print(
              '✅ [RESPONSE] ${response.statusCode} - ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          // ignore: avoid_print
          print(
              '❌ [ERROR] ${error.response?.statusCode ?? 'N/A'} - ${error.message}');
        }
        handler.next(error);
      },
    ));
  }

  /// Waits between retries of timeouts and connection errors.
  @visibleForTesting
  static List<Duration> connectionRetryDelays =
      AppConstants.connectionRetryDelays;

  static bool _isTransient(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    var reportedSlow = false;
    final slowTimer = Timer(AppConstants.slowConnectionThreshold, () {
      reportedSlow = true;
      NetworkFeedback.showSlowConnection();
    });

    try {
      var rateLimitAttempts = 0;
      var connectionAttempts = 0;
      while (true) {
        try {
          final response = await _dio.get<dynamic>(
            path,
            queryParameters: queryParameters,
            options: Options(),
            cancelToken: cancelToken,
          );

          if (response.statusCode == 200) {
            if (!_hasJsonBody(response.data)) {
              return ApiResult.error(
                ApiErrorType.invalidResponse,
                message: 'HTTP 200: empty or non-JSON response body',
              );
            }
            return ApiResult.success(response.data as T);
          }

          // Only other 2xx codes get here: Dio throws on the rest (429 included).
          return ApiResult.error(
            _errorTypeForStatus(response.statusCode),
            message:
                'HTTP ${response.statusCode}: ${response.data ?? 'no body'}',
          );
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) {
            return ApiResult.error(ApiErrorType.cancelled);
          }
          // A brief drop (tunnel, network switch) should not surface as an
          // error: retry a couple of times first.
          if (_isTransient(e) &&
              connectionAttempts < connectionRetryDelays.length) {
            await Future<void>.delayed(
              connectionRetryDelays[connectionAttempts++],
            );
            continue;
          }
          if (e.response?.statusCode == 429) {
            rateLimitAttempts++;
            if (rateLimitAttempts > AppConstants.tmdbMaxRateLimitRetries) {
              return ApiResult.error(ApiErrorType.rateLimit);
            }
            await Future<void>.delayed(
              _rateLimitDelay(
                attempt: rateLimitAttempts,
                headers: e.response?.headers.map,
              ),
            );
            continue;
          }
          return ApiResult.error(_errorTypeForDio(e));
        }
      }
    } on TypeError {
      // Unexpected payload shape, not a connection problem.
      return ApiResult.error(ApiErrorType.invalidResponse);
    } catch (_) {
      return ApiResult.error(
        ApiErrorType.networkError,
        message: AppL10n.current.errorNoConnection,
      );
    } finally {
      slowTimer.cancel();
      if (reportedSlow) {
        NetworkFeedback.dismissSlowConnection();
      }
    }
  }

  /// Delay before the next 429 retry: prefer Retry-After, else exponential backoff.
  Duration _rateLimitDelay({
    required int attempt,
    Map<String, List<String>>? headers,
  }) {
    final fromHeader = _retryAfterDelay(headers);
    if (fromHeader != null) return fromHeader;

    final seconds = 1 << (attempt - 1).clamp(0, 4); // 1, 2, 4, 8, 16
    final delay = Duration(seconds: seconds);
    if (delay > AppConstants.tmdbRateLimitRetryMaxDelay) {
      return AppConstants.tmdbRateLimitRetryMaxDelay;
    }
    return delay;
  }

  Duration? _retryAfterDelay(Map<String, List<String>>? headers) {
    if (headers == null) return null;
    final values = headers['retry-after'] ?? headers['Retry-After'];
    if (values == null || values.isEmpty) return null;

    final asSeconds = int.tryParse(values.first.trim());
    if (asSeconds == null) return null;

    final delay = Duration(seconds: asSeconds < 0 ? 0 : asSeconds);
    if (delay > AppConstants.tmdbRateLimitRetryMaxDelay) {
      return AppConstants.tmdbRateLimitRetryMaxDelay;
    }
    return delay;
  }

  /// Replaces the HTTP transport so tests can script responses.
  @visibleForTesting
  static set httpClientAdapter(HttpClientAdapter adapter) {
    instance._dio.httpClientAdapter = adapter;
  }

  static Future<void> init({String apiKey = ''}) async {
    _apiKey = apiKey;
    instance;
    if (apiKey.isNotEmpty && kDebugMode) {
      // ignore: avoid_print
      print('✅ DioClient initialized with API key');
    }
  }
}
