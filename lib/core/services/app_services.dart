import '../cache/cache_manager.dart';
import '../cache/api_cache_service.dart';
import '../background/background_task_runner.dart';
import '../debug/agent_debug_log.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/watch_record.dart';

/// Central services wrapper for easy access to all app services
class AppServices {
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;

  AppServices._internal();

  final CacheManager cacheManager = CacheManager();
  final ApiCacheService apiCacheService = ApiCacheService();
  late final TmdbService tmdbService =
      TmdbService(cacheManager: cacheManager);
  final BackgroundTaskRunner backgroundTaskRunner = BackgroundTaskRunner();

  final List<CatalogueItem> _catalogue = [];
  final List<WatchRecord> _watchHistory = [];

  List<CatalogueItem> get catalogue => List.unmodifiable(_catalogue);
  List<WatchRecord> get watchHistory => List.unmodifiable(_watchHistory);

  int get totalWatchTimeMinutes =>
      _watchHistory.fold(0, (sum, record) => sum + record.durationMinutes);

  int get filmsWatchedCount =>
      _watchHistory.where((record) => record.isFilm).length;

  int get episodesWatchedCount =>
      _watchHistory.where((record) => !record.isFilm).length;

  List<Film> get films =>
      _catalogue.whereType<Film>().toList(growable: false);

  List<TvShow> get tvShows =>
      _catalogue.whereType<TvShow>().toList(growable: false);

  bool isInCatalogue(int id) => _catalogue.any((item) => item.id == id);

  void addToCatalogue(CatalogueItem item) {
    if (isInCatalogue(item.id)) return;
    _catalogue.add(item);
    // #region agent log
    AgentDebugLog.log(
      location: 'app_services.dart:addToCatalogue',
      message: 'catalogue item added',
      hypothesisId: 'A',
      data: {
        'mediaId': item.id,
        'title': item.title,
        'isFilm': item is Film,
        'catalogueSize': _catalogue.length,
        'watchHistorySize': _watchHistory.length,
        'totalWatchTimeMinutes': totalWatchTimeMinutes,
      },
    );
    // #endregion
  }

  void removeFromCatalogue(int id) {
    _catalogue.removeWhere((item) => item.id == id);
  }

  void toggleCatalogueItem(CatalogueItem item) {
    if (isInCatalogue(item.id)) {
      removeFromCatalogue(item.id);
    } else {
      addToCatalogue(item);
    }
  }

  /// Adds a catalogue item and records watch time for films using TMDB runtime.
  Future<WatchRecord?> addToCatalogueWithWatchTime(CatalogueItem item) async {
    if (isInCatalogue(item.id)) return null;
    addToCatalogue(item);

    if (item is! Film) return null;

    final details = await tmdbService.getMediaDetails(item);
    final runtime = details?.runtimeMinutes ?? 0;
    // #region agent log
    AgentDebugLog.log(
      location: 'app_services.dart:addToCatalogueWithWatchTime',
      message: 'film runtime resolved for catalogue add',
      hypothesisId: 'D',
      data: {
        'mediaId': item.id,
        'title': item.title,
        'runtimeMinutes': runtime,
      },
      runId: 'post-fix',
    );
    // #endregion
    if (runtime <= 0) return null;

    return markFilmWatched(film: item, durationMinutes: runtime);
  }

  Future<void> toggleCatalogueItemAsync(CatalogueItem item) async {
    if (isInCatalogue(item.id)) {
      removeFromCatalogue(item.id);
      return;
    }

    if (item is Film) {
      await addToCatalogueWithWatchTime(item);
    } else {
      addToCatalogue(item);
    }
  }

  bool isWatched({required int mediaId, int? episodeId}) {
    if (episodeId != null) {
      return _watchHistory.any((record) => record.episodeId == episodeId);
    }
    return _watchHistory.any((record) => record.isFilm && record.mediaId == mediaId);
  }

  /// Records a watched film. Returns the new record, or null if already watched
  /// or duration is invalid.
  WatchRecord? markFilmWatched({
    required Film film,
    required int durationMinutes,
  }) {
    // #region agent log
    AgentDebugLog.log(
      location: 'app_services.dart:markFilmWatched',
      message: 'markFilmWatched called',
      hypothesisId: 'C',
      data: {
        'mediaId': film.id,
        'durationMinutes': durationMinutes,
        'alreadyWatched': isWatched(mediaId: film.id),
      },
    );
    // #endregion
    if (durationMinutes <= 0 || isWatched(mediaId: film.id)) return null;

    final record = WatchRecord(
      mediaId: film.id,
      mediaTitle: film.title,
      isFilm: true,
      durationMinutes: durationMinutes,
      watchedAt: DateTime.now(),
    );
    _watchHistory.add(record);
    // #region agent log
    AgentDebugLog.log(
      location: 'app_services.dart:markFilmWatched',
      message: 'watch record created',
      hypothesisId: 'C',
      data: {
        'mediaId': film.id,
        'durationMinutes': durationMinutes,
        'totalWatchTimeMinutes': totalWatchTimeMinutes,
        'watchHistorySize': _watchHistory.length,
      },
    );
    // #endregion
    return record;
  }

  /// Records a watched episode. Returns the new record, or null if already watched
  /// or duration is invalid.
  WatchRecord? markEpisodeWatched({
    required TvShow show,
    required EpisodeModel episode,
    int? fallbackRuntimeMinutes,
  }) {
    if (isWatched(mediaId: show.id, episodeId: episode.id)) return null;

    final duration = episode.runtimeMinutes ?? fallbackRuntimeMinutes ?? 0;
    if (duration <= 0) return null;

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
    _watchHistory.add(record);
    return record;
  }

  void unmarkEpisodeWatched(int episodeId) {
    _watchHistory.removeWhere((record) => record.episodeId == episodeId);
  }

  void unmarkFilmWatched(int mediaId) {
    _watchHistory.removeWhere(
      (record) => record.isFilm && record.mediaId == mediaId,
    );
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

  Future<void> initialize() async {
    tmdbService;
  }

  Future<void> startBackgroundTasks() async {
    await backgroundTaskRunner.start();
  }

  void dispose() {
    backgroundTaskRunner.dispose();
    cacheManager.dispose();
    apiCacheService.dispose();
    _catalogue.clear();
    _watchHistory.clear();
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

  Future<void> clearAllData() async {
    cacheManager.clearAll();
    _catalogue.clear();
    _watchHistory.clear();
  }
}
