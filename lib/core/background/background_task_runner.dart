import 'dart:async';
import '../constants/app_constants.dart';
import '../cache/cache_manager.dart';
import '../../data/services/movie_service.dart';
import '../../data/services/tv_show_service.dart';

/// Background task manager for periodic cache refreshes
class BackgroundTaskRunner {
  static final BackgroundTaskRunner _instance = BackgroundTaskRunner._internal();

  factory BackgroundTaskRunner() => _instance;

  BackgroundTaskRunner._internal();

  final MovieService movieService = MovieService();
  final TvShowService tvShowService = TvShowService();
  final CacheManager cacheManager = CacheManager();

  // Timer for periodic tasks
  Timer? _notificationCheckTimer;

  // Track last update times
  DateTime? _lastTrendingUpdate;
  DateTime? _lastEpisodeUpdate; // TODO: Use if needed

  static const Duration notificationCheckInterval =
      Duration(hours: AppConstants.notificationCheckIntervalHours);

  /// Start all background tasks
  Future<void> start() async {
    print('🚀 Starting background tasks...');

    // Start notification check timer (every 4 hours)
    _startNotificationChecks();

    // Initial checks
    await _performInitialTrendingCheck();
    await _performInitialEpisodeUpdate();

    print('✅ Background tasks started');
  }

  /// Start the periodic notification check timer
  void _startNotificationChecks() {
    if (_notificationCheckTimer != null) {
      return; // Already running
    }

    _notificationCheckTimer = Timer.periodic(notificationCheckInterval, (_) async {
      print('🔔 Running notification check cycle...');
      await _performNotificationCycle();
    });
  }

  /// Perform one full notification check cycle
  Future<void> _performNotificationCycle() async {
    try {
      // Check trending movies (cache refreshed every 12h)
      if (_shouldRefreshTrending()) {
        await _checkTrendingMovies();
      }

      // Check trending TV shows (cache refreshed every 12h)
      await _checkTrendingTvShows();

      print('✅ Notification cycle completed');
    } catch (e) {
      print('❌ Notification cycle error: $e');
    }
  }

  /// Check if it's time to refresh trending data
  bool _shouldRefreshTrending() {
    final now = DateTime.now();
    final lastUpdate = _lastTrendingUpdate ?? now;
    return now.difference(lastUpdate) >= notificationCheckInterval;
  }

  /// Perform initial trending check on app start
  Future<void> _performInitialTrendingCheck() async {
    print('📊 Initial trending data fetch...');

    try {
      await _checkTrendingMovies();
      await _checkTrendingTvShows();

      _lastTrendingUpdate = DateTime.now();
      print('✅ Initial trending check complete');
    } catch (e) {
      print('⚠️ Initial trending check failed: $e');
    }
  }

  /// Check and cache trending movies
  Future<void> _checkTrendingMovies() async {
    try {
      final trending = await movieService.getTrendingMovies();
      if (trending.isNotEmpty) {
        print('🎬 Cached ${trending.length} trending movies');

        // Update last update time
        _lastTrendingUpdate ??= DateTime.now();
        _lastTrendingUpdate = _lastTrendingUpdate!.add(const Duration(minutes: 12));
      }
    } catch (e) {
      print('❌ Error checking trending movies: $e');
    }
  }

  /// Check and cache trending TV shows
  Future<void> _checkTrendingTvShows() async {
    try {
      final trending = await tvShowService.getTrendingTvShows();
      if (trending.isNotEmpty) {
        print('📺 Cached ${trending.length} trending TV shows');

        // Update last update time
        _lastTrendingUpdate ??= DateTime.now();
        _lastTrendingUpdate = _lastTrendingUpdate!.add(const Duration(minutes: 12));
      }
    } catch (e) {
      print('❌ Error checking trending TV shows: $e');
    }
  }

  /// Check and update episode information (daily)
  Future<void> _performInitialEpisodeUpdate() async {
    // This would check user's catalogue for new episodes
    // For now, placeholder implementation
    print('📅 Episode update would run here...');
  }

  /// Stop all background tasks (for app suspend/logout)
  void stop() {
    print('⏸️ Stopping background tasks...');

    _notificationCheckTimer?.cancel();
    _notificationCheckTimer = null;

    // Clear timers to free memory
    _lastTrendingUpdate = null;
    _lastEpisodeUpdate = null;
  }

  /// Get current cache statistics for debugging
  Map<String, dynamic> getStatistics() {
    return cacheManager.getStatistics();
  }

  void dispose() {
    stop();
  }
}
