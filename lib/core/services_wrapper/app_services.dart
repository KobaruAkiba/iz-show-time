import '../cache/cache_manager.dart';
import '../cache/api_cache_service.dart';
import '../background/background_task_runner.dart';
import '../../data/services/movie_service.dart';
import '../../data/services/tv_show_service.dart';

/// Central services wrapper for easy access to all app services
class AppServices {
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;
  
  AppServices._internal();

  // Cache layer
  final CacheManager cacheManager = CacheManager();
  final ApiCacheService apiCacheService = ApiCacheService();
  
  // Services
  final MovieService movieService = MovieService();
  final TvShowService tvShowService = TvShowService();
  
  // Background tasks
  final BackgroundTaskRunner backgroundTaskRunner = BackgroundTaskRunner();

  /// Initialize all services
  Future<void> initialize() async {
    print('🔧 Initializing AppServices...');
    
    // Background tasks will be started here in main.dart
    
    print('✅ AppServices initialized');
  }

  /// Start background tasks (call after app initialization)
  Future<void> startBackgroundTasks() async {
    print('▶️ Starting background tasks...');
    await backgroundTaskRunner.start();
    
    // Log cache statistics
    print('📊 Cache Statistics: ${backgroundTaskRunner.getStatistics()}');
  }

  /// Stop all background services (call on app pause/logout)
  void dispose() {
    print('⏹️ Disposing AppServices...');
    backgroundTaskRunner.dispose();
    cacheManager.dispose();
    apiCacheService.dispose();
  }

  /// Get comprehensive cache statistics
  Map<String, dynamic> getFullStatistics() {
    return {
      'cache': backgroundTaskRunner.getStatistics(),
      'movies_cache_size': cacheManager.getStatistics()['movies_box_size'] ?? 0,
      'episodes_cache_size': cacheManager.getStatistics()['episodes_box_size'] ?? 0,
      'memory_cache_entries': cacheManager.getStatistics()["memory_cache_entries"] ?? 0,
    };
  }

  /// Clear all caches (for logout/clear data)
  Future<void> clearAllData() async {
    print('🗑️ Clearing all caches...');
    
    cacheManager.clearAll();
    
    print('✅ Caches cleared');
  }
}
