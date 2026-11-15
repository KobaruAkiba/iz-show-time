import 'package:flutter/foundation.dart';

import '../../data/models/new_episode_alert.dart';
import '../../data/models/watch_record.dart';
import '../../data/repositories/user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import '../network/network_feedback.dart';
import '../notifications/new_episode_checker.dart';
import '../utils/catalogue_activity.dart';
import 'catalogue_index.dart';
import 'watch_history_index.dart';

/// Continue Watching alerts: the next available episode of each followed show.
///
/// Owns the alert list and its refresh rules. Reads the catalogue and the
/// watch history but never changes them.
class EpisodeAlertsService {
  EpisodeAlertsService({
    required CatalogueIndex catalogue,
    required WatchHistoryIndex history,
    required TmdbService Function() tmdbService,
    required UserDataStore Function() userDataStore,
    required Future<void> Function() flushIfIdle,
  })  : _catalogue = catalogue,
        _history = history,
        _tmdbService = tmdbService,
        _userDataStore = userDataStore,
        _flushIfIdle = flushIfIdle;

  final CatalogueIndex _catalogue;
  final WatchHistoryIndex _history;

  // Looked up on each use: tests swap both after construction.
  final TmdbService Function() _tmdbService;
  final UserDataStore Function() _userDataStore;

  /// Flushes the store unless a larger user action will do it at its end.
  final Future<void> Function() _flushIfIdle;

  final List<NewEpisodeAlert> _alerts = [];
  final ValueNotifier<List<NewEpisodeAlert>> listenable =
      ValueNotifier<List<NewEpisodeAlert>>([]);

  /// Bumped when a watch-driven (per-show) refresh commits.
  /// Full network scans started earlier discard their result if this changed
  /// mid-flight, so they cannot restore a just-watched episode alert.
  int _watchDrivenEpoch = 0;

  List<NewEpisodeAlert> get alerts => List.unmodifiable(_alerts);

  void _publish() {
    listenable.value = List<NewEpisodeAlert>.from(_alerts);
  }

  /// Loads the stored alerts, dropping those of shows no longer followed.
  Future<void> loadFrom(UserDataStore store) async {
    _alerts
      ..clear()
      ..addAll(await store.loadNewEpisodeAlerts());
    final countBeforePrune = _alerts.length;
    final followedIds = _followedShowIds();
    _alerts.removeWhere((alert) => !followedIds.contains(alert.showId));
    _publish();
    if (_alerts.length == countBeforePrune) return;
    try {
      await store.saveNewEpisodeAlerts(_alerts);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to prune new episode alerts on init: $error\n$stackTrace',
      );
    }
  }

  /// Replaces the alerts, leaving out episodes already registered.
  void update(List<NewEpisodeAlert> alerts) {
    final pruned = [
      for (final alert in alerts)
        if (!_history.isEpisodeWatched(alert.episodeId)) alert,
    ];
    _alerts
      ..clear()
      ..addAll(pruned);
    _publish();
  }

  /// Drops any row for [episodeId] immediately so Home cannot keep showing a
  /// just-catalogued episode while a refresh is in flight.
  void removeForEpisode(int episodeId) {
    final before = _alerts.length;
    _alerts.removeWhere((alert) => alert.episodeId == episodeId);
    if (_alerts.length == before) return;
    _publish();
    _watchDrivenEpoch++;
  }

  Future<void> removeForShow(int showId) async {
    _alerts.removeWhere((alert) => alert.showId == showId);
    _publish();

    try {
      await _userDataStore().saveNewEpisodeAlerts(_alerts);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to remove episode data for show $showId: $error\n$stackTrace',
      );
    }
  }

  void clear() {
    _alerts.clear();
    listenable.value = const [];
    _watchDrivenEpoch = 0;
  }

  /// Adopts the alerts left by the background check when they are newer than
  /// the last check done by this isolate.
  Future<void> importBackgroundCheckResult() async {
    try {
      final store = _userDataStore();
      final result = await store.loadBackgroundCheckResult();
      if (result == null) return;
      final lastCheck = await store.loadLastEpisodeCheckAt();
      if (lastCheck != null && !result.checkedAt.isAfter(lastCheck)) return;

      // The background snapshot may predate an unfollow or a removal.
      final followedIds = _followedShowIds();
      update([
        for (final alert in result.alerts)
          if (followedIds.contains(alert.showId)) alert,
      ]);
      await store.saveNewEpisodeAlerts(_alerts);
      await store.saveLastEpisodeCheckAt(result.checkedAt);
      await _flushIfIdle();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to import background check result: $error\n$stackTrace',
      );
    }
  }

  /// Rebuilds the alerts from current catalogue progress so Home immediately
  /// shows the next aired episode after a watch change.
  ///
  /// Only followed shows are considered. When [forShowId] is set, only that
  /// show is rechecked and merged into existing alerts (avoids scanning the
  /// whole catalogue on every toggle).
  ///
  /// A slow full network scan must not commit after a newer watch-driven
  /// refresh: it may still hold a stale watch-history snapshot and would
  /// put a just-catalogued episode back into Continue Watching.
  Future<void> refresh({int? forShowId, bool forceRefresh = false}) async {
    final epochAtStart = _watchDrivenEpoch;
    final watchDriven = forShowId != null;
    await NetworkFeedback.runSilent(() async {
      try {
        final followed = _catalogue.followedTvShows;
        final shows = forShowId == null
            ? followed
            : followed
                .where((show) => show.id == forShowId)
                .toList(growable: false);
        final historySnapshot = List<WatchRecord>.of(_history.records);

        if (forShowId != null && shows.isEmpty) {
          _alerts.removeWhere((alert) => alert.showId == forShowId);
          _publish();
          await _persist();
          _watchDrivenEpoch++;
          return;
        }

        final checker = NewEpisodeChecker(
          tmdbService: _tmdbService(),
          userDataStore: _userDataStore(),
        );
        final result = await checker.checkShows(
          shows: shows,
          watchHistory: historySnapshot,
          forceRefresh: forceRefresh,
          mergeWithExisting: forShowId != null,
          existingAlerts: List<NewEpisodeAlert>.of(_alerts),
          persistAlerts: false,
        );
        final staleFullRefresh =
            !watchDriven && epochAtStart != _watchDrivenEpoch;
        if (staleFullRefresh) return;
        update(
          forShowId == null
              ? result.allAlerts
              : _mergeShowAlerts(forShowId, result.allAlerts),
        );
        await _persist();
        if (watchDriven) {
          _watchDrivenEpoch++;
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to refresh new episode alerts: $error\n$stackTrace',
        );
      }
    });
  }

  /// Current alerts with only [showId]'s entry replaced by [checked].
  ///
  /// [checked] is based on the alerts at check start: other shows' refreshes
  /// may have committed since, so their entries in it are stale.
  List<NewEpisodeAlert> _mergeShowAlerts(
    int showId,
    List<NewEpisodeAlert> checked,
  ) {
    final lastActivity = lastCatalogueActivityByMediaId(_history.records);
    return [
      ..._alerts.where((alert) => alert.showId != showId),
      ...checked.where((alert) => alert.showId == showId),
    ]..sort((a, b) => compareContinueWatchingAlerts(a, b, lastActivity));
  }

  Set<int> _followedShowIds() =>
      {for (final show in _catalogue.followedTvShows) show.id};

  Future<void> _persist() async {
    try {
      final store = _userDataStore();
      await store.saveNewEpisodeAlerts(_alerts);
      await store.saveLastEpisodeCheckAt(DateTime.now());
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to persist new episode alerts: $error\n$stackTrace',
      );
    }
  }
}
