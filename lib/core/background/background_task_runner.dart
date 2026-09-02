import 'dart:async';

import '../constants/app_constants.dart';
import '../cache/cache_manager.dart';
import '../services/app_services.dart';
import '../notifications/episode_check_service.dart';
import '../../data/services/tmdb_service.dart';

/// In-app refreshes while the app is open. System notifications are handled
/// exclusively by [NativeBackgroundScheduler].
class BackgroundTaskRunner {
  static final BackgroundTaskRunner _instance =
      BackgroundTaskRunner._internal();

  factory BackgroundTaskRunner() => _instance;

  BackgroundTaskRunner._internal();

  TmdbService get _tmdbService => AppServices().tmdbService;
  CacheManager get cacheManager => CacheManager();

  Timer? _foregroundRefreshTimer;
  DateTime? _lastTrendingUpdate;
  bool _cycleInProgress = false;

  static const Duration refreshInterval =
      Duration(hours: AppConstants.notificationCheckIntervalHours);

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _startForegroundRefreshTimer();
    unawaited(_performForegroundRefreshCycle());
  }

  void _startForegroundRefreshTimer() {
    if (_foregroundRefreshTimer != null) return;

    _foregroundRefreshTimer = Timer.periodic(refreshInterval, (_) async {
      await _performForegroundRefreshCycle();
    });
  }

  Future<void> _performForegroundRefreshCycle() async {
    if (_cycleInProgress) return;
    _cycleInProgress = true;

    try {
      if (_shouldRefreshTrending()) {
        await _checkTrending();
      }
      await _refreshNewEpisodesInApp();
    } catch (_) {
    } finally {
      _cycleInProgress = false;
    }
  }

  bool _shouldRefreshTrending() {
    final now = DateTime.now();
    final lastUpdate = _lastTrendingUpdate ?? now.subtract(refreshInterval);
    return now.difference(lastUpdate) >= refreshInterval;
  }

  Future<void> _checkTrending() async {
    final trending = await _tmdbService.getTrendingAll();
    if (trending.isNotEmpty) {
      _lastTrendingUpdate = DateTime.now();
    }
  }

  Future<void> _refreshNewEpisodesInApp() async {
    await EpisodeCheckService.refreshWhileAppOpen(AppServices());
  }

  void stop() {
    _foregroundRefreshTimer?.cancel();
    _foregroundRefreshTimer = null;
    _lastTrendingUpdate = null;
    _started = false;
  }

  Map<String, dynamic> getStatistics() => cacheManager.getStatistics();

  void dispose() => stop();
}
