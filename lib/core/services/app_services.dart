import 'package:flutter/foundation.dart';

import '../cache/cache_manager.dart';
import '../cache/api_cache_service.dart';
import '../background/background_task_runner.dart';
import '../notifications/new_episode_checker.dart';
import '../../data/repositories/hive_user_data_store.dart';
import '../../data/repositories/user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';
import '../../data/models/watch_record.dart';

/// Central services wrapper for easy access to all app services
class AppServices {
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;

  AppServices._internal();

  UserDataStore? _userDataStore;

  UserDataStore get userDataStore => _userDataStore ??= HiveUserDataStore();

  @visibleForTesting
  set userDataStore(UserDataStore store) => _userDataStore = store;

  final CacheManager cacheManager = CacheManager();
  final ApiCacheService apiCacheService = ApiCacheService();
  TmdbService? _tmdbService;
  TmdbService get tmdbService =>
      _tmdbService ??= TmdbService(cacheManager: cacheManager);

  @visibleForTesting
  set tmdbService(TmdbService service) => _tmdbService = service;

  final BackgroundTaskRunner backgroundTaskRunner = BackgroundTaskRunner();

  final List<CatalogueItem> _catalogue = [];
  final Map<int, CatalogueItem> _catalogueById = {};
  final List<WatchRecord> _watchHistory = [];
  final Set<int> _watchedEpisodeIds = {};
  final Set<int> _watchedFilmIds = {};
  final Map<int, int> _episodeCountByMediaId = {};
  final List<NewEpisodeAlert> _newEpisodeAlerts = [];
  final ValueNotifier<List<NewEpisodeAlert>> newEpisodeAlertsListenable =
      ValueNotifier<List<NewEpisodeAlert>>([]);

  /// When true, disk [UserDataStore.flush] is deferred until the outer
  /// mutating operation completes (enables one fsync per user action).
  bool _deferFlush = false;

  List<CatalogueItem> get catalogue => List.unmodifiable(_catalogue);
  List<WatchRecord> get watchHistory => List.unmodifiable(_watchHistory);
  List<NewEpisodeAlert> get newEpisodeAlerts =>
      List.unmodifiable(_newEpisodeAlerts);

  int get totalWatchTimeMinutes =>
      _watchHistory.fold(0, (sum, record) => sum + record.durationMinutes);

  int get filmsWatchedCount => _watchedFilmIds.length;

  int get episodesWatchedCount => _watchedEpisodeIds.length;

  List<Film> get films =>
      _catalogue.whereType<Film>().toList(growable: false);

  List<TvShow> get tvShows =>
      _catalogue.whereType<TvShow>().toList(growable: false);

  bool isInCatalogue(int id) => _catalogueById.containsKey(id);

  bool isFavorite(int id) => _catalogueById[id]?.isFavorite ?? false;

  Future<void> addToCatalogue(CatalogueItem item) async {
    if (isInCatalogue(item.id)) return;
    _catalogue.add(item);
    _catalogueById[item.id] = item;
    await _persistCatalogueItem(item);
  }

  Future<void> removeFromCatalogue(int id) async {
    await _withDeferredFlush(() async {
      _catalogue.removeWhere((item) => item.id == id);
      _catalogueById.remove(id);
      await _persistCatalogueRemoval(id);
      await _removeWatchHistoryForMedia(id);
      await _removeEpisodeDataForShow(id);
    });
  }

  /// Toggles the favorite flag on a catalogue item. No-op if not in catalogue.
  Future<void> toggleFavorite(int id) async {
    final index = _catalogue.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final updated = _catalogue[index].withFavorite(!_catalogue[index].isFavorite);
    _catalogue[index] = updated;
    _catalogueById[id] = updated;
    await _persistCatalogueItem(updated);
  }

  Future<void> toggleCatalogueItem(CatalogueItem item) async {
    if (isInCatalogue(item.id)) {
      await removeFromCatalogue(item.id);
    } else {
      await addToCatalogue(item);
    }
  }

  /// Adds a catalogue item and records watch time for films using TMDB runtime.
  Future<WatchRecord?> addToCatalogueWithWatchTime(CatalogueItem item) async {
    if (isInCatalogue(item.id)) return null;

    return _withDeferredFlush(() async {
      await addToCatalogue(item);

      if (item is! Film) return null;

      final details = await tmdbService.getMediaDetails(item);
      final runtime = details?.runtimeMinutes ?? 0;
      if (runtime <= 0) return null;

      return await markFilmWatched(film: item, durationMinutes: runtime);
    });
  }

  Future<void> toggleCatalogueItemAsync(CatalogueItem item) async {
    if (isInCatalogue(item.id)) {
      await removeFromCatalogue(item.id);
      return;
    }

    if (item is Film) {
      await addToCatalogueWithWatchTime(item);
    } else {
      await addToCatalogue(item);
    }
  }

  int watchedEpisodesCountFor(int mediaId) =>
      _episodeCountByMediaId[mediaId] ?? 0;

  List<WatchRecord> watchedEpisodesFor(int mediaId) => _watchHistory
      .where((record) => !record.isFilm && record.mediaId == mediaId)
      .toList(growable: false);

  /// Adds the series to the catalogue (if needed) and records the episode.
  Future<WatchRecord?> addEpisodeToCatalogue({
    required TvShow show,
    required EpisodeModel episode,
    int? fallbackRuntimeMinutes,
  }) async {
    return _withDeferredFlush(() async {
      if (!isInCatalogue(show.id)) {
        await addToCatalogue(show);
      }

      return await markEpisodeWatched(
        show: show,
        episode: episode,
        fallbackRuntimeMinutes: fallbackRuntimeMinutes,
      );
    });
  }

  /// Adds every non-upcoming episode of a season to the catalogue.
  /// Upcoming episodes (`episode.isUpcoming`) are skipped.
  /// Returns how many episodes were newly added.
  Future<int> addSeasonToCatalogue({
    required TvShow show,
    required List<EpisodeModel> episodes,
    int? fallbackRuntimeMinutes,
  }) async {
    if (episodes.isEmpty) return 0;

    return _withDeferredFlush(() async {
      if (!isInCatalogue(show.id)) {
        await addToCatalogue(show);
      }

      final now = DateTime.now();
      final toAdd = <WatchRecord>[];
      for (final episode in episodes) {
        if (episode.isUpcoming) continue;
        if (isWatched(mediaId: show.id, episodeId: episode.id)) continue;

        final duration = episode.runtimeMinutes ?? fallbackRuntimeMinutes ?? 0;
        if (duration <= 0) continue;

        toAdd.add(
          WatchRecord(
            mediaId: show.id,
            mediaTitle: show.title,
            isFilm: false,
            episodeId: episode.id,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber,
            durationMinutes: duration,
            watchedAt: now,
          ),
        );
      }

      if (toAdd.isEmpty) return 0;

      for (final record in toAdd) {
        _addWatchRecordInMemory(record);
      }
      await _persistWatchRecords(toAdd);
      await _refreshNewEpisodeAlerts(forShowId: show.id);
      return toAdd.length;
    });
  }

  /// Removes every episode of a season from the catalogue.
  /// Returns how many episodes were removed.
  Future<int> removeSeasonFromCatalogue({
    required List<EpisodeModel> episodes,
  }) async {
    if (episodes.isEmpty) return 0;

    return _withDeferredFlush(() async {
      final episodeIds = {
        for (final episode in episodes) episode.id,
      };
      final removedRecords = _watchHistory
          .where(
            (record) =>
                record.episodeId != null && episodeIds.contains(record.episodeId),
          )
          .toList(growable: false);
      if (removedRecords.isEmpty) return 0;

      final showId = removedRecords.first.mediaId;
      _removeWatchRecordsInMemory(removedRecords);
      await _persistWatchRecordRemovals(
        removedRecords.map((record) => record.watchKey),
      );
      await _refreshNewEpisodeAlerts(forShowId: showId);
      return removedRecords.length;
    });
  }

  bool isWatched({required int mediaId, int? episodeId}) {
    if (episodeId != null) {
      return _watchedEpisodeIds.contains(episodeId);
    }
    return _watchedFilmIds.contains(mediaId);
  }

  /// Adds the film to the catalogue (if needed) and records it as watched.
  /// Returns the new record, or null if already watched or duration is invalid.
  Future<WatchRecord?> markFilmWatched({
    required Film film,
    required int durationMinutes,
  }) async {
    if (durationMinutes <= 0 || isWatched(mediaId: film.id)) return null;

    return _withDeferredFlush(() async {
      if (!isInCatalogue(film.id)) {
        await addToCatalogue(film);
      }

      final record = WatchRecord(
        mediaId: film.id,
        mediaTitle: film.title,
        isFilm: true,
        durationMinutes: durationMinutes,
        watchedAt: DateTime.now(),
      );
      _addWatchRecordInMemory(record);
      await _persistWatchRecords([record]);
      return record;
    });
  }

  /// Records a watched episode. Returns the new record, or null if already watched
  /// or duration is invalid.
  Future<WatchRecord?> markEpisodeWatched({
    required TvShow show,
    required EpisodeModel episode,
    int? fallbackRuntimeMinutes,
  }) async {
    if (isWatched(mediaId: show.id, episodeId: episode.id)) return null;

    final duration = episode.runtimeMinutes ?? fallbackRuntimeMinutes ?? 0;
    if (duration <= 0) return null;

    return _withDeferredFlush(() async {
      final record = WatchRecord(
        mediaId: show.id,
        mediaTitle: show.title,
        isFilm: false,
        episodeId: episode.id,
        seasonNumber: episode.seasonNumber,
        episodeNumber: episode.episodeNumber,
        durationMinutes: duration,
        watchedAt: DateTime.now(),
      );
      _addWatchRecordInMemory(record);
      await _persistWatchRecords([record]);
      await _refreshNewEpisodeAlerts(forShowId: show.id);
      return record;
    });
  }

  Future<void> unmarkEpisodeWatched(int episodeId) async {
    await _withDeferredFlush(() async {
      final removedRecords = _watchHistory
          .where((record) => record.episodeId == episodeId)
          .toList(growable: false);
      if (removedRecords.isEmpty) return;

      final showId = removedRecords.first.mediaId;
      _removeWatchRecordsInMemory(removedRecords);
      await _persistWatchRecordRemovals(
        removedRecords.map((record) => record.watchKey),
      );
      await _refreshNewEpisodeAlerts(forShowId: showId);
    });
  }

  Future<void> unmarkFilmWatched(int mediaId) async {
    await _withDeferredFlush(() async {
      final removedRecords = _watchHistory
          .where((record) => record.isFilm && record.mediaId == mediaId)
          .toList(growable: false);
      if (removedRecords.isEmpty) return;

      _removeWatchRecordsInMemory(removedRecords);
      await _persistWatchRecordRemovals(
        removedRecords.map((record) => record.watchKey),
      );
    });
  }

  /// Search the user's catalogue and locally cached TMDB data.
  ({List<Film> films, List<TvShow> tvShows}) searchLocal(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return (films: <Film>[], tvShows: <TvShow>[]);
    }

    final films = <Film>[];
    final tvShows = <TvShow>[];
    final seenIds = <int>{};

    for (final item in _catalogue) {
      if (!item.title.toLowerCase().contains(normalizedQuery)) continue;
      if (!seenIds.add(item.id)) continue;
      if (item is Film) {
        films.add(item);
      } else if (item is TvShow) {
        tvShows.add(item);
      }
    }

    final cached = tmdbService.searchLocalCache(query: query);
    for (final film in cached.films) {
      if (seenIds.add(film.id)) films.add(film);
    }
    for (final show in cached.tvShows) {
      if (seenIds.add(show.id)) tvShows.add(show);
    }

    return (films: films, tvShows: tvShows);
  }

  Future<void> initialize({UserDataStore? userDataStore}) async {
    if (userDataStore != null) {
      _userDataStore = userDataStore;
    }

    final store = this.userDataStore;
    await store.open();
    _catalogue
      ..clear()
      ..addAll(await store.loadCatalogue());
    _rebuildCatalogueIndex();
    _watchHistory
      ..clear()
      ..addAll(await store.loadWatchHistory());
    _rebuildWatchIndexes();
    _newEpisodeAlerts
      ..clear()
      ..addAll(await store.loadNewEpisodeAlerts());
    newEpisodeAlertsListenable.value = List<NewEpisodeAlert>.from(
      _newEpisodeAlerts,
    );

    tmdbService;
  }

  void updateNewEpisodeAlerts(List<NewEpisodeAlert> alerts) {
    _newEpisodeAlerts
      ..clear()
      ..addAll(alerts);
    newEpisodeAlertsListenable.value = List<NewEpisodeAlert>.from(alerts);
  }

  Future<void> reloadNewEpisodeAlertsFromStore() async {
    try {
      final alerts = await userDataStore.loadNewEpisodeAlerts();
      updateNewEpisodeAlerts(alerts);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to reload new episode alerts: $error\n$stackTrace',
      );
    }
  }

  /// Rebuilds New Episodes from current catalogue progress so the home
  /// section immediately shows the next aired episode after a watch change.
  ///
  /// When [forShowId] is set, only that show is rechecked and merged into
  /// existing alerts (avoids scanning the whole catalogue on every toggle).
  Future<void> _refreshNewEpisodeAlerts({int? forShowId}) async {
    try {
      final shows = forShowId == null
          ? tvShows
          : tvShows.where((show) => show.id == forShowId).toList(growable: false);

      if (forShowId != null && shows.isEmpty) {
        _newEpisodeAlerts.removeWhere((alert) => alert.showId == forShowId);
        newEpisodeAlertsListenable.value = List<NewEpisodeAlert>.from(
          _newEpisodeAlerts,
        );
        await userDataStore.saveNewEpisodeAlerts(_newEpisodeAlerts);
        return;
      }

      final checker = NewEpisodeChecker(
        tmdbService: tmdbService,
        userDataStore: userDataStore,
      );
      final result = await checker.checkShows(
        shows: shows,
        watchHistory: watchHistory,
        forceRefresh: false,
        mergeWithExisting: forShowId != null,
      );
      updateNewEpisodeAlerts(result.allAlerts);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to refresh new episode alerts: $error\n$stackTrace',
      );
    }
  }

  Future<void> _removeWatchHistoryForMedia(int mediaId) async {
    final removedRecords = _watchHistory
        .where((record) => record.mediaId == mediaId)
        .toList(growable: false);
    if (removedRecords.isEmpty) return;

    _removeWatchRecordsInMemory(removedRecords);
    await _persistWatchRecordRemovals(
      removedRecords.map((record) => record.watchKey),
    );
  }

  Future<void> _removeEpisodeDataForShow(int showId) async {
    _newEpisodeAlerts.removeWhere((alert) => alert.showId == showId);
    newEpisodeAlertsListenable.value = List<NewEpisodeAlert>.from(
      _newEpisodeAlerts,
    );

    try {
      await userDataStore.saveNewEpisodeAlerts(_newEpisodeAlerts);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to remove episode data for show $showId: $error\n$stackTrace',
      );
    }
  }

  Future<void> startBackgroundTasks() async {
    await backgroundTaskRunner.start();
  }

  void dispose() {
    backgroundTaskRunner.dispose();
    cacheManager.dispose();
    apiCacheService.dispose();
  }

  void _rebuildCatalogueIndex() {
    _catalogueById
      ..clear()
      ..addEntries(_catalogue.map((item) => MapEntry(item.id, item)));
  }

  void _rebuildWatchIndexes() {
    _watchedEpisodeIds.clear();
    _watchedFilmIds.clear();
    _episodeCountByMediaId.clear();
    for (final record in _watchHistory) {
      _indexWatchRecord(record);
    }
  }

  void _addWatchRecordInMemory(WatchRecord record) {
    _watchHistory.add(record);
    _indexWatchRecord(record);
  }

  void _removeWatchRecordsInMemory(List<WatchRecord> records) {
    if (records.isEmpty) return;
    final keys = {for (final record in records) record.watchKey};
    _watchHistory.removeWhere((record) => keys.contains(record.watchKey));
    for (final record in records) {
      _unindexWatchRecord(record);
    }
  }

  void _indexWatchRecord(WatchRecord record) {
    if (record.isFilm) {
      _watchedFilmIds.add(record.mediaId);
      return;
    }
    final episodeId = record.episodeId;
    if (episodeId == null) return;
    if (_watchedEpisodeIds.add(episodeId)) {
      _episodeCountByMediaId.update(
        record.mediaId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  void _unindexWatchRecord(WatchRecord record) {
    if (record.isFilm) {
      _watchedFilmIds.remove(record.mediaId);
      return;
    }
    final episodeId = record.episodeId;
    if (episodeId == null) return;
    if (!_watchedEpisodeIds.remove(episodeId)) return;
    final remaining = (_episodeCountByMediaId[record.mediaId] ?? 1) - 1;
    if (remaining <= 0) {
      _episodeCountByMediaId.remove(record.mediaId);
    } else {
      _episodeCountByMediaId[record.mediaId] = remaining;
    }
  }

  Future<T> _withDeferredFlush<T>(Future<T> Function() action) async {
    final wasDeferring = _deferFlush;
    _deferFlush = true;
    try {
      final result = await action();
      return result;
    } finally {
      _deferFlush = wasDeferring;
      if (!_deferFlush) {
        await _flushUserData();
      }
    }
  }

  Future<void> _maybeFlush() async {
    if (!_deferFlush) {
      await _flushUserData();
    }
  }

  Future<void> _flushUserData() async {
    try {
      await userDataStore.flush();
    } catch (error, stackTrace) {
      debugPrint('Failed to flush user data store: $error\n$stackTrace');
    }
  }

  Future<void> _persistCatalogueItem(CatalogueItem item) async {
    try {
      await userDataStore.saveCatalogueItem(item);
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to persist catalogue item ${item.id}: $error\n$stackTrace',
      );
    }
  }

  Future<void> _persistCatalogueRemoval(int mediaId) async {
    try {
      await userDataStore.removeCatalogueItem(mediaId);
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to remove catalogue item $mediaId: $error\n$stackTrace',
      );
    }
  }

  Future<void> _persistWatchRecords(Iterable<WatchRecord> records) async {
    try {
      await userDataStore.saveWatchRecords(records);
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint('Failed to persist watch records: $error\n$stackTrace');
    }
  }

  Future<void> _persistWatchRecordRemovals(Iterable<String> watchKeys) async {
    try {
      await userDataStore.removeWatchRecords(watchKeys);
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint('Failed to remove watch records: $error\n$stackTrace');
    }
  }

  Map<String, dynamic> getFullStatistics() {
    return {
      'cache': backgroundTaskRunner.getStatistics(),
      'movies_cache_size': cacheManager.getStatistics()['movies_box_size'] ?? 0,
      'episodes_cache_size':
          cacheManager.getStatistics()['episodes_box_size'] ?? 0,
      'memory_cache_entries':
          cacheManager.getStatistics()['memory_cache_entries'] ?? 0,
      'catalogue_items': _catalogue.length,
      'watch_time_minutes': totalWatchTimeMinutes,
      'films_watched': filmsWatchedCount,
      'episodes_watched': episodesWatchedCount,
    };
  }

  /// Clears in-memory API/call cache only. Catalogue and watch history are kept.
  void clearCacheData() {
    cacheManager.clearAll();
    apiCacheService.clearPending();
  }

  Future<void> clearAllData() async {
    cacheManager.clearAll();
    apiCacheService.clearPending();
    _catalogue.clear();
    _catalogueById.clear();
    _watchHistory.clear();
    _watchedEpisodeIds.clear();
    _watchedFilmIds.clear();
    _episodeCountByMediaId.clear();
    _newEpisodeAlerts.clear();
    newEpisodeAlertsListenable.value = const [];
    await userDataStore.clearAll();
  }
}
