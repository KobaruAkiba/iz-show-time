import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../../l10n/l10n.dart';

/// Custom error types for API responses
enum ApiErrorType {
  rateLimit,
  notFound,
  unauthorized,
  invalidResponse,
  networkError,
}

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
        message: message ?? _getErrorMessage(type),
      );

  static String _getErrorMessage(ApiErrorType type) {
    final l10n = AppL10n.current;
    switch (type) {
      case ApiErrorType.rateLimit:
        return l10n.errorTooManyRequests;
      case ApiErrorType.notFound:
        return l10n.errorResourceNotFound;
      case ApiErrorType.unauthorized:
        return l10n.errorAccessDenied;
      case ApiErrorType.invalidResponse:
        return l10n.errorInvalidResponse;
      default:
        return l10n.errorGeneric;
    }
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
        await Future.delayed(const Duration(seconds: 5));
        return get<T>(path, queryParameters: queryParameters);
      }

      return ApiResult.error(
        _errorTypeForStatus(response.statusCode),
        message: 'HTTP ${response.statusCode}: ${response.data ?? 'no body'}',
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        return ApiResult.error(
          ApiErrorType.networkError,
          message: 'Connection timeout',
        );
      }
      return ApiResult.error(ApiErrorType.networkError, message: e.toString());
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
