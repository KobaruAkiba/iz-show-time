import 'dart:async';

import '../constants/app_constants.dart';

import '../cache/cache_manager.dart';

import '../services/app_services.dart';

import '../notifications/new_episode_checker.dart';

import '../notifications/notification_service.dart';

import '../../data/services/tmdb_service.dart';



/// Background task manager for periodic cache refreshes and episode checks.

class BackgroundTaskRunner {

  static final BackgroundTaskRunner _instance =

      BackgroundTaskRunner._internal();



  factory BackgroundTaskRunner() => _instance;



  BackgroundTaskRunner._internal();



  TmdbService get _tmdbService => AppServices().tmdbService;

  CacheManager get cacheManager => CacheManager();



  Timer? _notificationCheckTimer;

  DateTime? _lastTrendingUpdate;

  bool _cycleInProgress = false;



  static const Duration notificationCheckInterval =

      Duration(hours: AppConstants.notificationCheckIntervalHours);



  bool _started = false;



  Future<void> start() async {

    if (_started) return;

    _started = true;

    _startNotificationChecks();

    unawaited(_performNotificationCycle());

  }



  void _startNotificationChecks() {

    if (_notificationCheckTimer != null) return;



    _notificationCheckTimer =

        Timer.periodic(notificationCheckInterval, (_) async {

      await _performNotificationCycle();

    });

  }



  Future<void> _performNotificationCycle() async {

    if (_cycleInProgress) return;

    _cycleInProgress = true;



    try {

      if (_shouldRefreshTrending()) {

        await _checkTrending();

      }

      await _checkNewEpisodes();

    } catch (_) {

    } finally {

      _cycleInProgress = false;

    }

  }



  bool _shouldRefreshTrending() {

    final now = DateTime.now();

    final lastUpdate =

        _lastTrendingUpdate ?? now.subtract(notificationCheckInterval);

    return now.difference(lastUpdate) >= notificationCheckInterval;

  }



  Future<void> _checkTrending() async {

    final trending = await _tmdbService.getTrendingAll();

    if (trending.isNotEmpty) {

      _lastTrendingUpdate = DateTime.now();

    }

  }



  Future<void> _checkNewEpisodes() async {

    final appServices = AppServices();

    final shows = appServices.tvShows;

    if (shows.isEmpty) return;



    final checker = NewEpisodeChecker(

      tmdbService: appServices.tmdbService,

      userDataStore: appServices.userDataStore,

    );



    final result = await checker.checkShows(
      shows: shows,
      watchHistory: appServices.watchHistory,
    );

    appServices.updateNewEpisodeAlerts(result.allAlerts);



    if (result.newlyDetected.isNotEmpty) {

      await NotificationService().showNewEpisodesNotification(

        count: result.newlyDetected.length,

      );

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

