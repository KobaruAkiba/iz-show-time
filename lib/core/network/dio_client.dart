import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';

/// Custom error types for API responses
enum ApiErrorType {
  rateLimit,           // Too many requests (429)
  notFound,            // Resource not found (404)
  unauthorized,        // Unauthorized (401)
  invalidResponse,     // Invalid response format (4xx/5xx)
  networkError,        // Network issues (timeout, no internet)
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
    switch (type) {
      case ApiErrorType.rateLimit:
        return 'Too many requests. Please wait a moment.';
      case ApiErrorType.notFound:
        return 'Resource not found.';
      case ApiErrorType.unauthorized:
        return 'Access denied. API key may be invalid.';
      case ApiErrorType.invalidResponse:
        return 'Invalid response from server.';
      default:
        return 'An error occurred';
    }
  }
}

/// Main HTTP client for TMDB API
class DioClient {
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._internal();
  
  final Dio _dio;
  
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

  void _setupInterceptors() {
    // Logging for debugging
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('📡 [REQUEST] ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ [RESPONSE] ${response.statusCode} - ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ [ERROR] ${error.response?.statusCode ?? 'N/A'} - ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Perform a GET request
  Future<ApiResult<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(),
      );
      
      if (response.statusCode == 200) {
        return ApiResult.success(response.data as T);
      } else if (response.statusCode == 429) {
        // Rate limit exceeded - wait a bit and retry
        await Future.delayed(const Duration(seconds: 5));
        return get<T>(path, queryParameters: queryParameters);
      }
      
      return ApiResult.error(
        ApiErrorType.invalidResponse,
        message: 'HTTP ${response.statusCode}: ${response.data}',
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        return ApiResult.error(ApiErrorType.networkError, message: 'Connection timeout');
      }
      return ApiResult.error(ApiErrorType.networkError, message: e.toString());
    }
  }

  /// Get all request headers
  Map<String, String> get headers => _dio.options.headers.cast<String, String>();

  /// Update base URL if needed
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// Reset the client (useful for testing)
  factory DioClient.reset() {
    _instance = null;
    return instance;
  }

  /// Static helper method to initialize with API key
  static Future<void> init({String apiKey = ''}) async {
    if (apiKey.isNotEmpty) {
      // Log that client is initialized with API key
      print('✅ DioClient initialized with API key');
    }
  }
}
