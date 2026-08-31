import '../network/dio_client.dart';
import '../constants/app_constants.dart';
import './cache_manager.dart';

/// Service that wraps API calls with caching, rate limiting, and deduplication
class ApiCacheService {
  static final ApiCacheService _instance = ApiCacheService._internal();
  factory ApiCacheService() => _instance;
  
  ApiCacheService._internal();

  final DioClient dioClient = DioClient.instance;
  final CacheManager cacheManager = CacheManager();
  
  // Rate limit tracking
  int _requestsInWindow = 0;
  DateTime? _windowStart;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  static const int maxRequestsPerWindow = AppConstants.tmdbMaxRequestsPerMinute;

  // Request deduplication (if same request within 2s, return cached)
  Map<String, DateTime> _pendingRequests = {};
  static const Duration pendingRequestTTL = Duration(seconds: 2);

  /// Execute API call with automatic caching
  Future<dynamic> executeWithCache<T>(
    String path, {
    required Function(String path, Object data) bodyBuilder,
    Function? onCacheHit,
    Function? onCacheMiss,
    int cacheTTLMinutes = AppConstants.defaultCacheTTLMinutes,
  }) async {
    final key = '${DateTime.now().millisecondsSinceEpoch}_$path';
    
    // Check if we have a pending request for this key (deduplication)
    if (_pendingRequests.containsKey(key)) {
      print('⏳ Duplicate request deduplicated: $path');
      return _waitForPendingRequest<T>(key, path);
    }

    // Mark as pending
    _pendingRequests[key] = DateTime.now();

    // Try cache first
    try {
      final cached = cacheManager.get<T>(key);
      if (cached != null) {
        print('💾 Cache HIT: $path');
        cacheManager.put(key, cached, ttlMinutes: cacheTTLMinutes);
        onCacheHit?.call(path, cached);
        return cached;
      }
    } catch (e) {
      print('⚠️ Cache read error for $path: $e');
    }

    // Check rate limit before making request
    if (!_checkRateLimit()) {
      throw Exception('API rate limit exceeded. Waiting...');
    }

    // No cache, make API call
    try {
      final result = await dioClient.get<T>(path, queryParameters: {});
      
      if (!result.isSuccess) {
        throw Exception(result.message);
      }
      
      print('📡 API request succeeded: $path');
      
      // Store in cache
      cacheManager.put(
        key, 
        result.data,
        ttlMinutes: cacheTTLMinutes,
      );
      
      onCacheMiss?.call(path, result.data);
      
      return result.data;
    } catch (e) {
      print('❌ API error for $path: $e');
      
      // Handle rate limit specifically
      if (e.toString().contains('429')) {
        await _handleRateLimit();
        return await executeWithCache<T>(
          path,
          bodyBuilder: bodyBuilder,
          onCacheHit: onCacheHit,
          onCacheMiss: onCacheMiss,
          cacheTTLMinutes: cacheTTLMinutes,
        );
      }
      
      rethrow;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(key);
    }
  }

  /// Execute POST request with caching (for updates)
  Future<dynamic> executePostWithCache<T>(
    String path,
    Map<String, dynamic> body, {
    int cacheTTLMinutes = 0, // No cache for POST operations typically
  }) async {
    final key = '${DateTime.now().millisecondsSinceEpoch}_POST_$path';
    
    if (!_checkRateLimit()) {
      throw Exception('API rate limit exceeded');
    }

    try {
      // Note: Using DioClient.get as wrapper for now
      print('📡 POST request not yet implemented');
      throw Exception('POST not implemented in DioClient yet');
    } catch (e) {
      print('❌ POST error for $path: $e');
      rethrow;
    }
  }

  /// Wait for pending request to complete (used during deduplication)
  Future<dynamic> _waitForPendingRequest<T>(String key, String path) async {
    // This is a simplified approach - in production use proper async/await pattern
    // For now, we'll just wait and try again
    await Future.delayed(pendingRequestTTL);
    
    if (_pendingRequests.containsKey(key)) {
      final cached = cacheManager.get<T>(key);
      if (cached != null) {
        return cached;
      }
    }
    
    // Should not happen in normal flow, but fallback to re-execute
    throw Exception('Duplicate request timeout');
  }

  /// Check if we're within rate limit window
  bool _checkRateLimit() {
    final now = DateTime.now();
    
    // Initialize window
    if (_windowStart == null || 
        now.difference(_windowStart!).inMinutes >= maxRequestsPerWindow) {
      _windowStart = now;
      _requestsInWindow = 0;
    }
    
    if (_requestsInWindow >= maxRequestsPerWindow) {
      return false; // Rate limited
    }
    
    _requestsInWindow++;
    return true;
  }

  /// Handle rate limit exceeded (429 error)
  Future<void> _handleRateLimit() async {
    final waitTime = DateTime.now().difference(_windowStart!).inSeconds;
    if (waitTime >= maxRequestsPerWindow) {
      // Window reset, proceed
      _requestsInWindow = 0;
    } else {
      // Wait until window resets
      final secondsToWait = maxRequestsPerWindow - waitTime;
      print('⏱️ Rate limit: waiting ${secondsToWait}s...');
      await Future.delayed(Duration(seconds: secondsToWait));
      _requestsInWindow = 0;
      _windowStart = DateTime.now();
    }
  }

  /// Clear pending requests (e.g., after app restart)
  void clearPending() {
    _pendingRequests.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    return cacheManager.getStatistics()..addAll({
      'active_requests': _pendingRequests.length,
      'requests_this_window': _requestsInWindow,
      'window_start': _windowStart != null ? _windowStart!.toIso8601String() : null,
    });
  }

  void dispose() {
    cacheManager.dispose();
  }
}
