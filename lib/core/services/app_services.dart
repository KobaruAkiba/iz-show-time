import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../cache/cache_manager.dart';
import '../cache/tmdb_disk_cache.dart';
import '../background/background_task_runner.dart';
import '../constants/storage_constants.dart';
import '../network/api_error.dart';
import '../network/network_feedback.dart';
import '../theme/app_theme.dart';
import 'bookmark_only_shows_migration.dart';
import 'catalogue_index.dart';
import 'episode_alerts_service.dart';
import 'library_status.dart';
import 'watch_history_index.dart';
import 'watchlist_service.dart';
import '../../data/repositories/hive_user_data_store.dart';
import '../../data/repositories/user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/media_details.dart';
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
  TmdbService? _tmdbService;
  TmdbService get tmdbService => _tmdbService ??= TmdbService(
        cacheManager: cacheManager,
        diskCache: tmdbDiskCache,
      );

  /// Persistent TMDB cache; set at startup, before [tmdbService] is first
  /// used. Left null in the background isolate and in tests.
  TmdbDiskCache? tmdbDiskCache;

  @visibleForTesting
  set tmdbService(TmdbService service) => _tmdbService = service;

  final BackgroundTaskRunner backgroundTaskRunner = BackgroundTaskRunner();

  /// Empties the on-disk image cache; part of the TMDB cache purge.
  /// Set at startup so this class does not depend on the image plugin.
  Future<void> Function()? imageDiskCachePurge;

  final CatalogueIndex _catalogue = CatalogueIndex();
  final WatchHistoryIndex _history = WatchHistoryIndex();
  late final EpisodeAlertsService _alerts = EpisodeAlertsService(
    catalogue: _catalogue,
    history: _history,
    tmdbService: () => tmdbService,
    userDataStore: () => userDataStore,
    flushIfIdle: _maybeFlush,
  );

  /// Titles saved to watch later; only [addToCatalogue] moves them into the
  /// catalogue.
  late final WatchlistService watchlist = WatchlistService(
    store: () => userDataStore,
    flushIfIdle: _maybeFlush,
    isInCatalogue: isInCatalogue,
  );

  ValueNotifier<List<NewEpisodeAlert>> get newEpisodeAlertsListenable =>
      _alerts.listenable;
  final ValueNotifier<ThemeMode> themeModeListenable =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// When true the catalogue header shows a catalogue summary instead of
  /// total watch time.
  final ValueNotifier<bool> hideWatchTimeListenable =
      ValueNotifier<bool>(false);

  /// While positive, disk [UserDataStore.flush] is deferred until every
  /// mutating operation in flight completes (one fsync per user action).
  /// A counter, not a flag: operations can overlap.
  int _deferFlushDepth = 0;

  static const Duration _airingStatesSyncInterval = Duration(minutes: 15);
  DateTime? _lastAiringStatesSyncAt;

  ThemeMode get themeMode => themeModeListenable.value;

  bool get hideWatchTime => hideWatchTimeListenable.value;

  List<CatalogueItem> get catalogue => _catalogue.items;
  List<WatchRecord> get watchHistory => _history.records;
  List<NewEpisodeAlert> get newEpisodeAlerts => _alerts.alerts;

  int get totalWatchTimeMinutes => _history.totalMinutes;

  int get filmsWatchedCount => _history.filmCount;

  int get episodesWatchedCount => _history.episodeCount;

  List<Film> get films => _catalogue.films;

  List<TvShow> get tvShows => _catalogue.tvShows;

  /// TV shows marked as followed; only these feed New Episodes / notifications.
  List<TvShow> get followedTvShows => _catalogue.followedTvShows;

  bool isInCatalogue(CatalogueItem item) => _catalogue.contains(item);

  LibraryStatus libraryStatusOf(CatalogueItem item) {
    if (isInCatalogue(item)) return LibraryStatus.catalogue;
    if (watchlist.contains(item)) return LibraryStatus.watchlist;
    return LibraryStatus.none;
  }

  bool isFavorite(CatalogueItem item) =>
      _catalogue.find(item)?.isFavorite ?? false;

  bool isFollowed(int id) => _catalogue.tvShowById(id)?.isFollowed ?? false;

  Future<void> addToCatalogue(CatalogueItem item) async {
    if (isInCatalogue(item)) return;
    var localItem =
        item.overview == null ? item : catalogueItemForLocalStore(item);
    // New TV shows are followed by default so they appear in New Episodes.
    if (localItem is TvShow && !localItem.isFollowed) {
      localItem = localItem.withFollowed(true);
    }
    _catalogue.add(localItem);
    // Single watchlist -> catalogue transition; every add path goes through here.
    await watchlist.remove(localItem);
    await _persistCatalogueItem(localItem);
    if (localItem is TvShow) {
      unawaited(syncTvShowAiringState(localItem.id));
    }
  }

  /// Persists TMDB airing metadata used by the catalogue In Progress and
  /// Caught Up filters.
  Future<void> updateTvShowAiringState(
    int id, {
    String? status,
    String? nextEpisodeAirDate,
    int? lastAiredSeasonNumber,
    int? lastAiredEpisodeNumber,
  }) async {
    final item = _catalogue.tvShowById(id);
    if (item == null) return;

    final nextStatus = _nonEmptyTrimmed(status);
    final nextDate = _nonEmptyTrimmed(nextEpisodeAirDate);
    // Season and episode are stored only as a pair.
    final hasLastAired =
        lastAiredSeasonNumber != null && lastAiredEpisodeNumber != null;
    final lastSeason = hasLastAired ? lastAiredSeasonNumber : null;
    final lastEpisode = hasLastAired ? lastAiredEpisodeNumber : null;
    if (item.status == nextStatus &&
        item.nextEpisodeAirDate == nextDate &&
        item.lastAiredSeasonNumber == lastSeason &&
        item.lastAiredEpisodeNumber == lastEpisode) {
      return;
    }

    final updated = item.copyWith(
      status: nextStatus,
      nextEpisodeAirDate: nextDate,
      lastAiredSeasonNumber: lastSeason,
      lastAiredEpisodeNumber: lastEpisode,
      clearStatus: nextStatus == null,
      clearNextEpisodeAirDate: nextDate == null,
      clearLastAiredEpisode: !hasLastAired,
    );
    _catalogue.add(updated);
    await _persistCatalogueItem(updated);
  }

  /// Applies airing fields from already-fetched [details] when the show is
  /// in the local catalogue.
  Future<void> applyTvShowAiringDetails(int id, MediaDetails details) async {
    if (details.isFilm) return;
    await updateTvShowAiringState(
      id,
      status: details.status,
      nextEpisodeAirDate: details.nextEpisodeAirDate,
      lastAiredSeasonNumber: details.lastAiredSeasonNumber,
      lastAiredEpisodeNumber: details.lastAiredEpisodeNumber,
    );
  }

  /// Refreshes TMDB status / next-episode date for one catalogue TV show.
  Future<void> syncTvShowAiringState(int id) async {
    await NetworkFeedback.runSilent(() async {
      final item = _catalogue.tvShowById(id);
      if (item == null) return;
      try {
        final details = await tmdbService.getMediaDetails(item);
        if (details == null) return;
        await applyTvShowAiringDetails(id, details);
      } on ApiException {
        // Keep last known airing state on network/API failure.
      }
    });
  }

  /// Refreshes airing metadata for every catalogue TV show (uses TMDB cache).
  ///
  /// Called on every Catalogue tab activation, so it is throttled.
  Future<void> syncTvShowAiringStates() async {
    final now = DateTime.now();
    final last = _lastAiringStatesSyncAt;
    if (last != null && now.difference(last) < _airingStatesSyncInterval) {
      return;
    }
    _lastAiringStatesSyncAt = now;
    await NetworkFeedback.runSilent(() async {
      for (final show in List<TvShow>.from(tvShows)) {
        try {
          final details = await tmdbService.getMediaDetails(show);
          if (details == null) continue;
          await applyTvShowAiringDetails(show.id, details);
        } on ApiException {
          continue;
        }
      }
    });
  }

  Future<void> removeFromCatalogue(CatalogueItem item) async {
    await _withDeferredFlush(() async {
      _catalogue.remove(item);
      await _persistCatalogueRemoval(item);
      await _removeWatchHistoryForMedia(item);
      if (item.isTvShow) {
        await _alerts.removeForShow(item.id);
      }
    });
  }

  /// Toggles the favorite flag on a catalogue item. No-op if not in catalogue.
  Future<void> toggleFavorite(CatalogueItem item) async {
    final current = _catalogue.find(item);
    if (current == null) return;

    final updated = current.withFavorite(!current.isFavorite);
    _catalogue.add(updated);
    await _persistCatalogueItem(updated);
  }

  /// Toggles followed on a catalogue TV show. No-op for films or missing items.
  ///
  /// Unfollowing clears that show's New Episode alerts; following rechecks it.
  Future<void> toggleFollowed(int id) async {
    final item = _catalogue.tvShowById(id);
    if (item == null) return;

    final updated = item.withFollowed(!item.isFollowed) as TvShow;
    _catalogue.add(updated);
    await _persistCatalogueItem(updated);

    if (updated.isFollowed) {
      await _alerts.refresh(forShowId: id);
    } else {
      await _alerts.removeForShow(id);
    }
  }

  /// Adds a catalogue item and records watch time for films using TMDB runtime.
  Future<WatchRecord?> addToCatalogueWithWatchTime(CatalogueItem item) async {
    if (isInCatalogue(item)) return null;

    return _withDeferredFlush(() async {
      await addToCatalogue(item);

      if (item is! Film) return null;

      try {
        final details = await tmdbService.getMediaDetails(item);
        final runtime = details?.runtimeMinutes ?? 0;
        if (runtime <= 0) return null;

        return await markFilmWatched(film: item, durationMinutes: runtime);
      } on ApiException {
        return null;
      }
    });
  }

  /// Search bookmark: removes a catalogued title, adds a film to the catalogue
  /// (recording watch time) and sends a TV show to the watchlist.
  Future<LibraryToggleResult> toggleCatalogueItem(CatalogueItem item) async {
    if (isInCatalogue(item)) {
      await removeFromCatalogue(item);
      return LibraryToggleResult.removedFromCatalogue;
    }

    if (item is Film) {
      await addToCatalogueWithWatchTime(item);
      return LibraryToggleResult.addedToCatalogue;
    }

    return switch (await watchlist.add(item)) {
      WatchlistAddResult.added => LibraryToggleResult.addedToWatchlist,
      WatchlistAddResult.alreadyPresent =>
        LibraryToggleResult.alreadyOnWatchlist,
      // Catalogued meanwhile by another action.
      WatchlistAddResult.alreadyInCatalogue =>
        LibraryToggleResult.addedToCatalogue,
    };
  }

  int watchedEpisodesCountFor(int mediaId) => _history.episodeCountFor(mediaId);

  /// Whether removing [episodeIds] would leave the show with no catalogued
  /// episodes. Bookmark-only shows (zero episodes) return `false`.
  bool wouldRemoveLastCataloguedEpisodes({
    required int mediaId,
    required Iterable<int> episodeIds,
  }) {
    final total = watchedEpisodesCountFor(mediaId);
    if (total == 0) return false;

    var removing = 0;
    for (final episodeId in episodeIds) {
      if (isWatched(mediaId: mediaId, episodeId: episodeId)) {
        removing++;
      }
    }
    return removing >= total;
  }

  List<WatchRecord> watchedEpisodesFor(int mediaId) =>
      _history.episodesFor(mediaId);

  /// Adds the series to the catalogue (if needed) and records the episode.
  Future<WatchRecord?> addEpisodeToCatalogue({
    required TvShow show,
    required EpisodeModel episode,
    int? fallbackRuntimeMinutes,
  }) async {
    return markEpisodeWatched(
      show: show,
      episode: episode,
      fallbackRuntimeMinutes: fallbackRuntimeMinutes,
    );
  }

  /// Adds every catalogue-addable episode of a season to the catalogue.
  /// Upcoming and airing-soon episodes (no resolvable runtime) are skipped.
  /// Returns how many episodes were newly added.
  Future<int> addSeasonToCatalogue({
    required TvShow show,
    required List<EpisodeModel> episodes,
    int? fallbackRuntimeMinutes,
  }) async {
    if (episodes.isEmpty) return 0;

    return _withDeferredFlush(() async {
      final now = DateTime.now();
      final toAdd = <WatchRecord>[];
      for (final episode in episodes) {
        final peerAverage = EpisodeModel.averagePositiveRuntimeMinutes(
          episodes,
          excludeEpisodeId: episode.id,
        );
        final fallback = fallbackRuntimeMinutes ?? peerAverage;
        if (!episode.isCatalogueAddable(fallbackRuntimeMinutes: fallback)) {
          continue;
        }
        if (isWatched(mediaId: show.id, episodeId: episode.id)) continue;

        final duration = episode.resolvedRuntimeMinutes(
          fallbackRuntimeMinutes: fallback,
        );

        toAdd.add(
          WatchRecord(
            mediaId: show.id,
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

      if (!isInCatalogue(show)) {
        await addToCatalogue(show);
        // A second tap may have registered episodes during the await.
        toAdd.removeWhere(
          (record) =>
              isWatched(mediaId: show.id, episodeId: record.episodeId),
        );
        if (toAdd.isEmpty) return 0;
      }

      toAdd.forEach(_history.add);
      await _persistWatchRecords(toAdd);
      await _alerts.refresh(forShowId: show.id);
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
      final removedRecords = _history.records
          .where(
            (record) =>
                record.episodeId != null &&
                episodeIds.contains(record.episodeId),
          )
          .toList(growable: false);
      if (removedRecords.isEmpty) return 0;

      final showId = removedRecords.first.mediaId;
      _history.removeAll(removedRecords);
      await _persistWatchRecordRemovals(
        removedRecords.map((record) => record.watchKey),
      );
      await _alerts.refresh(forShowId: showId);
      return removedRecords.length;
    });
  }

  bool isWatched({required int mediaId, int? episodeId}) =>
      _history.isWatched(mediaId: mediaId, episodeId: episodeId);

  /// Adds the film to the catalogue (if needed) and records it as watched.
  /// Returns the new record, or null if already watched or duration is invalid.
  Future<WatchRecord?> markFilmWatched({
    required Film film,
    required int durationMinutes,
  }) async {
    if (durationMinutes <= 0 || isWatched(mediaId: film.id)) return null;

    return _withDeferredFlush(() async {
      if (!isInCatalogue(film)) {
        await addToCatalogue(film);
        // A second tap may have recorded the film during the await.
        if (isWatched(mediaId: film.id)) return null;
      }

      final record = WatchRecord(
        mediaId: film.id,
        isFilm: true,
        durationMinutes: durationMinutes,
        watchedAt: DateTime.now(),
      );
      _history.add(record);
      await _persistWatchRecords([record]);
      return record;
    });
  }

  /// Records a watched episode. Ensures the series is in the catalogue.
  /// Returns the new record, or null if already watched or not catalogue-addable.
  Future<WatchRecord?> markEpisodeWatched({
    required TvShow show,
    required EpisodeModel episode,
    int? fallbackRuntimeMinutes,
  }) async {
    if (isWatched(mediaId: show.id, episodeId: episode.id)) return null;

    if (!episode.isCatalogueAddable(
      fallbackRuntimeMinutes: fallbackRuntimeMinutes,
    )) {
      return null;
    }

    final duration = episode.resolvedRuntimeMinutes(
      fallbackRuntimeMinutes: fallbackRuntimeMinutes,
    );

    return _withDeferredFlush(() async {
      if (!isInCatalogue(show)) {
        await addToCatalogue(show);
        // A second tap may have recorded the episode during the await.
        if (isWatched(mediaId: show.id, episodeId: episode.id)) return null;
      }

      final record = WatchRecord(
        mediaId: show.id,
        isFilm: false,
        episodeId: episode.id,
        seasonNumber: episode.seasonNumber,
        episodeNumber: episode.episodeNumber,
        durationMinutes: duration,
        watchedAt: DateTime.now(),
      );
      _history.add(record);
      await _persistWatchRecords([record]);
      _alerts.removeForEpisode(episode.id);
      await _alerts.refresh(forShowId: show.id);
      return record;
    });
  }

  Future<void> unmarkEpisodeWatched(int episodeId) async {
    await _withDeferredFlush(() async {
      final removedRecords = _history.records
          .where((record) => record.episodeId == episodeId)
          .toList(growable: false);
      if (removedRecords.isEmpty) return;

      final showId = removedRecords.first.mediaId;
      _history.removeAll(removedRecords);
      await _persistWatchRecordRemovals(
        removedRecords.map((record) => record.watchKey),
      );
      await _alerts.refresh(forShowId: showId);
    });
  }

  Future<void> unmarkFilmWatched(int mediaId) async {
    await _withDeferredFlush(() async {
      final removedRecords = _history.records
          .where((record) => record.isFilm && record.mediaId == mediaId)
          .toList(growable: false);
      if (removedRecords.isEmpty) return;

      _history.removeAll(removedRecords);
      await _persistWatchRecordRemovals(
        removedRecords.map((record) => record.watchKey),
      );
    });
  }

  /// Search the user's catalogue and locally cached TMDB data.
  List<CatalogueItem> searchLocal(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return <CatalogueItem>[];
    }

    final items = <CatalogueItem>[];
    final seenKeys = <String>{};

    for (final item in _catalogue.items) {
      if (!item.title.toLowerCase().contains(normalizedQuery)) continue;
      if (!seenKeys.add(item.mediaKey)) continue;
      items.add(item);
    }

    for (final item in tmdbService.searchLocalCache(query: query)) {
      if (!seenKeys.add(item.mediaKey)) continue;
      items.add(item);
    }

    return items;
  }

  Future<void> initialize({UserDataStore? userDataStore}) async {
    if (userDataStore != null) {
      _userDataStore = userDataStore;
    }

    final store = this.userDataStore;
    await store.open();
    _catalogue.replaceAll(await store.loadCatalogue());
    _history.replaceAll(await store.loadWatchHistory());
    try {
      await BookmarkOnlyShowsMigration(
        store: store,
        catalogue: _catalogue,
        history: _history,
      ).run();
    } catch (error, stackTrace) {
      // Startup goes on; without the flag the migration retries next launch.
      debugPrint('Failed bookmark-only shows migration: $error\n$stackTrace');
    }
    await watchlist.loadFrom(store);
    await _alerts.loadFrom(store);

    try {
      themeModeListenable.value = AppTheme.themeModeFromStorage(
        await store.loadThemeMode(),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load theme mode: $error\n$stackTrace');
      themeModeListenable.value = ThemeMode.system;
    }

    try {
      hideWatchTimeListenable.value = await store.loadHideWatchTime();
    } catch (error, stackTrace) {
      debugPrint('Failed to load hide watch time: $error\n$stackTrace');
      hideWatchTimeListenable.value = false;
    }

    await importBackgroundCheckResult();
    await _purgeTmdbCachesIfStale();

    tmdbService;
  }

  /// TMDB API Terms of Use: do not cache TMDB information longer than 6 months.
  /// Clears non-catalogue caches only (in-memory API cache + Flutter image cache).
  Future<void> _purgeTmdbCachesIfStale() async {
    try {
      final last = await userDataStore.loadLastTmdbCachePurgeAt();
      final now = DateTime.now().toUtc();
      if (last == null ||
          now.difference(last.toUtc()) >= StorageConstants.tmdbCacheMaxAge) {
        await clearCacheData();
      }
    } catch (error, stackTrace) {
      debugPrint('Failed TMDB cache compliance purge: $error\n$stackTrace');
    }
  }

  /// Updates the app theme preference and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeModeListenable.value == mode) return;
    themeModeListenable.value = mode;
    try {
      await userDataStore.saveThemeMode(AppTheme.themeModeToStorage(mode));
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint('Failed to persist theme mode: $error\n$stackTrace');
    }
  }

  /// Shows or hides total watch time in the catalogue and persists it.
  Future<void> setHideWatchTime(bool hidden) async {
    if (hideWatchTimeListenable.value == hidden) return;
    hideWatchTimeListenable.value = hidden;
    try {
      await userDataStore.saveHideWatchTime(hidden);
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint('Failed to persist hide watch time: $error\n$stackTrace');
    }
  }

  void updateNewEpisodeAlerts(List<NewEpisodeAlert> alerts) =>
      _alerts.update(alerts);

  /// Adopts the alerts left by the background check when they are newer than
  /// the last check done by this isolate.
  Future<void> importBackgroundCheckResult() =>
      _alerts.importBackgroundCheckResult();

  /// Foreground network refresh of followed-show alerts (no system notify).
  Future<void> refreshNewEpisodeAlertsFromNetwork() =>
      _alerts.refresh(forceRefresh: true);

  Future<void> _removeWatchHistoryForMedia(CatalogueItem item) async {
    final key = item.mediaKey;
    final removedRecords = _history.records
        .where((record) => record.mediaKey == key)
        .toList(growable: false);
    if (removedRecords.isEmpty) return;

    _history.removeAll(removedRecords);
    await _persistWatchRecordRemovals(
      removedRecords.map((record) => record.watchKey),
    );
  }

  Future<void> startBackgroundTasks() async {
    await backgroundTaskRunner.start(
      tmdbService: tmdbService,
      onForegroundRefresh: refreshNewEpisodeAlertsFromNetwork,
    );
  }

  void dispose() {
    backgroundTaskRunner.dispose();
    cacheManager.dispose();
  }

  Future<T> _withDeferredFlush<T>(Future<T> Function() action) async {
    _deferFlushDepth++;
    try {
      return await action();
    } finally {
      _deferFlushDepth--;
      if (_deferFlushDepth == 0) {
        await _flushUserData();
      }
    }
  }

  Future<void> _maybeFlush() async {
    if (_deferFlushDepth == 0) {
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

  Future<void> _persistCatalogueRemoval(CatalogueItem item) async {
    try {
      await userDataStore.removeCatalogueItem(item);
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to remove catalogue item ${item.mediaKey}: $error\n$stackTrace',
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

  /// Clears in-memory API/call cache and Flutter image cache only.
  /// Catalogue and watch history are kept. Records the purge time for TMDB ToU.
  Future<void> clearCacheData() async {
    cacheManager.clearAll();
    _clearFlutterImageCache();
    try {
      await tmdbDiskCache?.clear();
      await imageDiskCachePurge?.call();
    } catch (error, stackTrace) {
      debugPrint('Failed to empty the disk caches: $error\n$stackTrace');
    }
    try {
      await userDataStore.saveLastTmdbCachePurgeAt(DateTime.now().toUtc());
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint(
          'Failed to persist TMDB cache purge time: $error\n$stackTrace');
    }
  }

  void _clearFlutterImageCache() {
    try {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    } catch (_) {
      // Binding may be unavailable in headless unit tests.
    }
  }

  Future<void> clearAllData() async {
    await clearCacheData();
    _catalogue.clear();
    _history.clear();
    _alerts.clear();
    watchlist.clear();
    _lastAiringStatesSyncAt = null;
    await userDataStore.clearAll();
    // clearAll removes the purge stamp; re-record so the next launch is not forced.
    try {
      await userDataStore.saveLastTmdbCachePurgeAt(DateTime.now().toUtc());
      await _maybeFlush();
    } catch (error, stackTrace) {
      debugPrint(
          'Failed to persist TMDB cache purge time: $error\n$stackTrace');
    }
  }

  Future<String> exportUserDataBackup() async {
    final data = await userDataStore.exportBackupData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> restoreUserDataBackup(String jsonBackup) async {
    final decoded = jsonDecode(jsonBackup);
    if (decoded is! Map) {
      throw const FormatException('Invalid backup file');
    }

    await userDataStore.importBackupData(Map<String, dynamic>.from(decoded));
    await initialize(userDataStore: userDataStore);
  }
}

String? _nonEmptyTrimmed(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
