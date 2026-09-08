import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../../l10n/l10n.dart';
import 'api_error.dart';
import 'network_feedback.dart';

export 'api_error.dart';

/// API Result wrapper for consistent error handling
class ApiResult<T> {
  final bool isSuccess;
  final T? data;
  final ApiErrorType error;
  final String message;

  ApiResult({
    required this.isSuccess,
    this.data,
    required this.error,
    required this.message,
  });

  factory ApiResult.success(T data) => ApiResult(
        isSuccess: true,
        data: data,
        error: ApiErrorType.networkError,
        message: 'Success',
      );

  factory ApiResult.error(ApiErrorType type, {String? message}) => ApiResult(
        isSuccess: false,
        data: null,
        error: type,
        message: message ?? apiErrorMessage(type),
      );

  /// Throws [ApiException] when this result is not a success.
  T getOrThrow() {
    if (isSuccess && data != null) return data as T;
    throw ApiException(error, message);
  }
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

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    var reportedSlow = false;
    final slowTimer = Timer(AppConstants.slowConnectionThreshold, () {
      reportedSlow = true;
      NetworkFeedback.showSlowConnection();
    });

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(),
      );

      if (response.statusCode == 200) {
        if (!_hasJsonBody(response.data)) {
          return ApiResult.error(
            ApiErrorType.invalidResponse,
            message: 'HTTP 200: empty or non-JSON response body',
          );
        }
        return ApiResult.success(response.data as T);
      } else if (response.statusCode == 429) {
        slowTimer.cancel();
        if (reportedSlow) NetworkFeedback.dismissSlowConnection();
        await Future.delayed(const Duration(seconds: 5));
        return get<T>(path, queryParameters: queryParameters);
      }

      return ApiResult.error(
        _errorTypeForStatus(response.statusCode),
        message: 'HTTP ${response.statusCode}: ${response.data ?? 'no body'}',
      );
    } on DioException catch (e) {
      final type = _errorTypeForDio(e);
      return ApiResult.error(type);
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

  Map<String, String> get headers => _dio.options.headers.cast<String, String>();

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  factory DioClient.reset() {
    _instance = null;
    return instance;
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
