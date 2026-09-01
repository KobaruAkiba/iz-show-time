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

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _startNotificationChecks();
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
        await _checkTrending();
      }
    } catch (_) {}
  }

  bool _shouldRefreshTrending() {
    final now = DateTime.now();
    final lastUpdate = _lastTrendingUpdate ?? now.subtract(notificationCheckInterval);
    return now.difference(lastUpdate) >= notificationCheckInterval;
  }

  Future<void> _checkTrending() async {
    final trending = await _tmdbService.getTrendingAll();
    if (trending.isNotEmpty) {
      _lastTrendingUpdate = DateTime.now();
    }
  }

  void stop() {
    _notificationCheckTimer?.cancel();
    _notificationCheckTimer = null;
    _lastTrendingUpdate = null;
    _started = false;
  }

  Map<String, dynamic> getStatistics() => cacheManager.getStatistics();

  void dispose() => stop();
}
