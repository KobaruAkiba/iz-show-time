import 'dart:async';

import '../constants/app_constants.dart';
import '../../data/services/tmdb_service.dart';

/// In-app refreshes while the app is open. System notifications are handled
/// exclusively by [NativeBackgroundScheduler].
class BackgroundTaskRunner {
  static final BackgroundTaskRunner _instance =
      BackgroundTaskRunner._internal();

  factory BackgroundTaskRunner() => _instance;

  BackgroundTaskRunner._internal();

  TmdbService? _tmdbService;
  Future<void> Function()? _onForegroundRefresh;

  Timer? _foregroundRefreshTimer;
  DateTime? _lastTrendingUpdate;
  bool _cycleInProgress = false;

  static const Duration refreshInterval =
      Duration(hours: AppConstants.notificationCheckIntervalHours);

  bool _started = false;

  Future<void> start({
    required TmdbService tmdbService,
    required Future<void> Function() onForegroundRefresh,
  }) async {
    if (_started) return;
    _started = true;
    _tmdbService = tmdbService;
    _onForegroundRefresh = onForegroundRefresh;
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
    final tmdb = _tmdbService;
    if (tmdb == null) return;

    final trending = await tmdb.getTrendingAll();
    if (trending.isNotEmpty) {
      _lastTrendingUpdate = DateTime.now();
    }
  }

  Future<void> _refreshNewEpisodesInApp() async {
    final refresh = _onForegroundRefresh;
    if (refresh == null) return;
    await refresh();
  }

  void stop() {
    _foregroundRefreshTimer?.cancel();
    _foregroundRefreshTimer = null;
    _lastTrendingUpdate = null;
    _tmdbService = null;
    _onForegroundRefresh = null;
    _started = false;
  }

  void dispose() => stop();
}
