import 'dart:async';
import '../constants/app_constants.dart';
import '../cache/cache_manager.dart';
import '../services/app_services.dart';
import '../../data/services/tmdb_service.dart';

/// Background task manager for periodic cache refreshes
class BackgroundTaskRunner {
  static final BackgroundTaskRunner _instance =
      BackgroundTaskRunner._internal();

  factory BackgroundTaskRunner() => _instance;

  BackgroundTaskRunner._internal();

  TmdbService get _tmdbService => AppServices().tmdbService;
  CacheManager get cacheManager => CacheManager();

  Timer? _notificationCheckTimer;
  DateTime? _lastTrendingUpdate;

  static const Duration notificationCheckInterval =
      Duration(hours: AppConstants.notificationCheckIntervalHours);

  Future<void> start() async {
    _startNotificationChecks();
    await _performInitialTrendingCheck();
  }

  void _startNotificationChecks() {
    if (_notificationCheckTimer != null) return;

    _notificationCheckTimer =
        Timer.periodic(notificationCheckInterval, (_) async {
      await _performNotificationCycle();
    });
  }

  Future<void> _performNotificationCycle() async {
    try {
      if (_shouldRefreshTrending()) {
        await _checkTrendingMovies();
        await _checkTrendingTvShows();
      }
    } catch (_) {}
  }

  bool _shouldRefreshTrending() {
    final now = DateTime.now();
    final lastUpdate = _lastTrendingUpdate ?? now.subtract(notificationCheckInterval);
    return now.difference(lastUpdate) >= notificationCheckInterval;
  }

  Future<void> _performInitialTrendingCheck() async {
    try {
      await _checkTrendingMovies();
      await _checkTrendingTvShows();
      _lastTrendingUpdate = DateTime.now();
    } catch (_) {}
  }

  Future<void> _checkTrendingMovies() async {
    final trending = await _tmdbService.getTrendingMovies();
    if (trending.isNotEmpty) {
      _lastTrendingUpdate = DateTime.now();
    }
  }

  Future<void> _checkTrendingTvShows() async {
    final trending = await _tmdbService.getTrendingTv();
    if (trending.isNotEmpty) {
      _lastTrendingUpdate = DateTime.now();
    }
  }

  void stop() {
    _notificationCheckTimer?.cancel();
    _notificationCheckTimer = null;
    _lastTrendingUpdate = null;
  }

  Map<String, dynamic> getStatistics() => cacheManager.getStatistics();

  void dispose() => stop();
}
