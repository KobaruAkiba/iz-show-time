import '../network/dio_client.dart';
import '../constants/app_constants.dart';
import 'cache_manager.dart';

/// Service that wraps API calls with caching, rate limiting, and deduplication
class ApiCacheService {
  static final ApiCacheService _instance = ApiCacheService._internal();
  factory ApiCacheService() => _instance;

  ApiCacheService._internal();

  final DioClient dioClient = DioClient.instance;
  final CacheManager cacheManager = CacheManager();

  int _requestsInWindow = 0;
  DateTime? _windowStart;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  static const int maxRequestsPerWindow = AppConstants.tmdbMaxRequestsPerMinute;

  final Map<String, DateTime> _pendingRequests = {};
  static const Duration pendingRequestTTL = Duration(seconds: 2);

  Future<dynamic> executeWithCache<T>(
    String path, {
    required Function(String path, Object data) bodyBuilder,
    Function? onCacheHit,
    Function? onCacheMiss,
    int cacheTTLMinutes = AppConstants.defaultCacheTTLMinutes,
    Map<String, dynamic>? queryParameters,
  }) async {
    final key = _buildCacheKey(path, queryParameters);

    if (_pendingRequests.containsKey(key)) {
      return _waitForPendingRequest<T>(key);
    }

    _pendingRequests[key] = DateTime.now();

    try {
      final cached = cacheManager.get<T>(key);
      if (cached != null) {
        onCacheHit?.call(path, cached);
        return cached;
      }

      if (!_checkRateLimit()) {
        throw Exception('API rate limit exceeded. Waiting...');
      }

      final result = await dioClient.get<T>(
        path,
        queryParameters: queryParameters,
      );

      if (!result.isSuccess) {
        throw Exception(result.message);
      }

      cacheManager.put(
        key,
        result.data,
        ttlMinutes: cacheTTLMinutes,
      );

      onCacheMiss?.call(path, result.data);
      return result.data;
    } catch (e) {
      if (e.toString().contains('429')) {
        await _handleRateLimit();
        return executeWithCache<T>(
          path,
          bodyBuilder: bodyBuilder,
          onCacheHit: onCacheHit,
          onCacheMiss: onCacheMiss,
          cacheTTLMinutes: cacheTTLMinutes,
          queryParameters: queryParameters,
        );
      }
      rethrow;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  Future<dynamic> _waitForPendingRequest<T>(String key) async {
    await Future.delayed(pendingRequestTTL);
    final cached = cacheManager.get<T>(key);
    if (cached != null) return cached;
    throw Exception('Duplicate request timeout');
  }

  String _buildCacheKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return path;
    final sortedKeys = queryParameters.keys.toList()..sort();
    final query =
        sortedKeys.map((k) => '$k=${queryParameters[k]}').join('&');
    return '$path?$query';
  }

  bool _checkRateLimit() {
    final now = DateTime.now();

    if (_windowStart == null ||
        now.difference(_windowStart!) >= rateLimitWindow) {
      _windowStart = now;
      _requestsInWindow = 0;
    }

    if (_requestsInWindow >= maxRequestsPerWindow) {
      return false;
    }

    _requestsInWindow++;
    return true;
  }

  Future<void> _handleRateLimit() async {
    final waitTime = DateTime.now().difference(_windowStart!).inSeconds;
    if (waitTime >= maxRequestsPerWindow) {
      _requestsInWindow = 0;
    } else {
      final secondsToWait = maxRequestsPerWindow - waitTime;
      await Future.delayed(Duration(seconds: secondsToWait));
      _requestsInWindow = 0;
      _windowStart = DateTime.now();
    }
  }

  void clearPending() {
    _pendingRequests.clear();
  }

  Map<String, dynamic> getStatistics() {
    return cacheManager.getStatistics()
      ..addAll({
        'active_requests': _pendingRequests.length,
        'requests_this_window': _requestsInWindow,
        'window_start': _windowStart?.toIso8601String(),
      });
  }

  void dispose() {
    clearPending();
  }
}
