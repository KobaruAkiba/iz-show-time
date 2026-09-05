import 'dart:async';

import '../../core/network/dio_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_constants.dart';
import '../../core/cache/cache_manager.dart';
import '../models/catalogue_item.dart';
import '../models/episode_model.dart';
import '../models/media_details.dart';
import '../models/season_model.dart';

/// Unified TMDB API service with caching and JSON parsing
class TmdbService {
  TmdbService({CacheManager? cacheManager})
      : _cache = cacheManager ?? CacheManager();

  final CacheManager _cache;
  final Map<String, Future<dynamic>> _inflight = {};

  Future<List<CatalogueItem>> getTrendingAll() async {
    final results = await _fetchResults(
      'trending/all/day',
      ttlMinutes: AppConstants.tvCacheTTL,
    );
    return results
        .map(catalogueItemFromSearchJson)
        .whereType<CatalogueItem>()
        .toList();
  }

  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    final isFilm = item is Film;
    final path = isFilm ? 'movie/${item.id}' : 'tv/${item.id}';
    final data = await _fetchSingle(
      path,
      extraParams: {
        'append_to_response': isFilm
            ? ApiConstants.movieAppendToResponse
            : ApiConstants.tvAppendToResponse,
      },
      ttlMinutes: isFilm
          ? AppConstants.movieDetailsCacheTTL
          : AppConstants.tvDetailsCacheTTL,
    );
    if (data == null) return null;
    return MediaDetails.fromTmdbJson(data, isFilm: isFilm);
  }

  /// Searches TMDB multi endpoint. Pass [page] to fetch subsequent pages.
  /// TMDB returns a fixed ~20 results per page; UI may window further locally.
  Future<
      ({
        List<Film> films,
        List<TvShow> tvShows,
        int page,
        int totalPages,
      })> searchMulti({
    required String query,
    int page = 1,
  }) async {
    if (query.trim().isEmpty) {
      return (
        films: <Film>[],
        tvShows: <TvShow>[],
        page: 1,
        totalPages: 0,
      );
    }

    final safePage = page < 1 ? 1 : page;
    final pageData = await _fetchPagedResults(
      'search/multi',
      extraParams: {
        'query': query,
        'page': '$safePage',
      },
      ttlMinutes: AppConstants.searchCacheTTL,
    );

    final parsed = _parseSearchResults(pageData.results);
    return (
      films: parsed.films,
      tvShows: parsed.tvShows,
      page: pageData.page,
      totalPages: pageData.totalPages,
    );
  }

  /// Search films and shows already stored in the local API cache.
  ({List<Film> films, List<TvShow> tvShows}) searchLocalCache({
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return (films: <Film>[], tvShows: <TvShow>[]);
    }

    final films = <Film>[];
    final tvShows = <TvShow>[];
    final seenIds = <int>{};

    for (final key in _cache.keys) {
      _collectCachedMatches(
        key: key,
        query: normalizedQuery,
        seenIds: seenIds,
        films: films,
        tvShows: tvShows,
      );
    }

    return (films: films, tvShows: tvShows);
  }

  ({List<Film> films, List<TvShow> tvShows}) _parseSearchResults(
    List<Map<String, dynamic>> results,
  ) {
    final films = <Film>[];
    final tvShows = <TvShow>[];

    for (final item in results) {
      final parsed = catalogueItemFromSearchJson(item);
      if (parsed is Film) {
        films.add(parsed);
      } else if (parsed is TvShow) {
        tvShows.add(parsed);
      }
    }

    return (films: films, tvShows: tvShows);
  }

  void _collectCachedMatches({
    required String key,
    required String query,
    required Set<int> seenIds,
    required List<Film> films,
    required List<TvShow> tvShows,
  }) {
    if (_isCachedListKey(key)) {
      final list = _cache.get<List<dynamic>>(key);
      if (list == null) return;

      for (final entry in list) {
        if (entry is! Map<String, dynamic>) continue;
        _tryAddLocalMatch(
          item: _parseCachedListItem(entry, key),
          query: query,
          seenIds: seenIds,
          films: films,
          tvShows: tvShows,
        );
      }
      return;
    }

    if (_isCachedMovieDetailKey(key)) {
      final data = _cache.get<Map<String, dynamic>>(key);
      if (data == null) return;
      _tryAddLocalMatch(
        item: _safeParse(() => Film.fromJson(data)),
        query: query,
        seenIds: seenIds,
        films: films,
        tvShows: tvShows,
      );
      return;
    }

    if (_isCachedTvDetailKey(key)) {
      final data = _cache.get<Map<String, dynamic>>(key);
      if (data == null) return;
      _tryAddLocalMatch(
        item: _safeParse(() => TvShow.fromJson(data)),
        query: query,
        seenIds: seenIds,
        films: films,
        tvShows: tvShows,
      );
    }
  }

  bool _isCachedListKey(String key) {
    // Pagination metadata keys store a Map, not a result list.
    if (key.contains('#meta')) return false;
    return key.startsWith('search/multi') || key.contains('trending/');
  }

  bool _isCachedMovieDetailKey(String key) {
    return RegExp(r'^movie/\d+\?').hasMatch(key);
  }

  bool _isCachedTvDetailKey(String key) {
    return RegExp(r'^tv/\d+\?').hasMatch(key) && !key.contains('/season/');
  }

  CatalogueItem? _parseCachedListItem(
    Map<String, dynamic> json,
    String cacheKey,
  ) {
    final fromSearch = catalogueItemFromSearchJson(json);
    if (fromSearch != null) return fromSearch;

    if (cacheKey.contains('movie')) {
      return _safeParse(() => Film.fromJson(json));
    }
    if (cacheKey.contains('/tv') || cacheKey.startsWith('tv/')) {
      return _safeParse(() => TvShow.fromJson(json));
    }
    return null;
  }

  CatalogueItem? _safeParse(CatalogueItem Function() parse) {
    try {
      return parse();
    } catch (_) {
      return null;
    }
  }

  void _tryAddLocalMatch({
    required CatalogueItem? item,
    required String query,
    required Set<int> seenIds,
    required List<Film> films,
    required List<TvShow> tvShows,
  }) {
    if (item == null || !item.title.toLowerCase().contains(query)) return;
    if (!seenIds.add(item.id)) return;

    if (item is Film) {
      films.add(item);
    } else if (item is TvShow) {
      tvShows.add(item);
    }
  }

  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    final season = await getSeason(
      tvId: tvId,
      seasonNumber: seasonNumber,
      forceRefresh: forceRefresh,
    );
    return season?.episodes ?? const [];
  }

  Future<SeasonModel?> getSeason({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    final data = await _fetchSingle(
      'tv/$tvId/season/$seasonNumber',
      ttlMinutes: AppConstants.episodeCacheTTL,
      bypassCache: forceRefresh,
    );
    if (data == null) return null;
    return SeasonModel.fromTmdbSeasonJson(data);
  }

  Future<List<SeasonModel>> getTvSeasons({
    required int tvId,
    required int numberOfSeasons,
  }) async {
    if (numberOfSeasons <= 0) return const [];

    final seasons = await Future.wait(
      List.generate(
        numberOfSeasons,
        (index) => getSeason(
          tvId: tvId,
          seasonNumber: index + 1,
        ),
      ),
    );

    return [
      for (var i = 0; i < seasons.length; i++)
        seasons[i] ??
            SeasonModel(seasonNumber: i + 1, episodes: const []),
    ];
  }

  Future<List<Map<String, dynamic>>> _fetchResults(
    String path, {
    Map<String, String>? extraParams,
    int? ttlMinutes,
    String resultsKey = 'results',
    bool bypassCache = false,
  }) async {
    final paged = await _fetchPagedResults(
      path,
      extraParams: extraParams,
      ttlMinutes: ttlMinutes,
      resultsKey: resultsKey,
      bypassCache: bypassCache,
    );
    return paged.results;
  }

  Future<
      ({
        List<Map<String, dynamic>> results,
        int page,
        int totalPages,
      })> _fetchPagedResults(
    String path, {
    Map<String, String>? extraParams,
    int? ttlMinutes,
    String resultsKey = 'results',
    bool bypassCache = false,
  }) async {
    final params = _baseParams(extraParams);
    final cacheKey = _buildCacheKey(path, params);
    final metaCacheKey = '$cacheKey#meta';

    if (!bypassCache) {
      final cached = _cache.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        final meta = _cache.get<Map<String, dynamic>>(metaCacheKey);
        return (
          results: cached.whereType<Map<String, dynamic>>().toList(),
          page: (meta?['page'] as int?) ?? 1,
          totalPages: (meta?['total_pages'] as int?) ?? 1,
        );
      }
    }

    if (AppApiKey.tmdb.isEmpty) {
      return (
        results: <Map<String, dynamic>>[],
        page: 1,
        totalPages: 0,
      );
    }

    return _dedupe(cacheKey, () async {
      final cachedAfterWait = _cache.get<List<dynamic>>(cacheKey);
      if (cachedAfterWait != null) {
        final meta = _cache.get<Map<String, dynamic>>(metaCacheKey);
        return (
          results: cachedAfterWait.whereType<Map<String, dynamic>>().toList(),
          page: (meta?['page'] as int?) ?? 1,
          totalPages: (meta?['total_pages'] as int?) ?? 1,
        );
      }

      try {
        final result = await DioClient.instance.get<Map<String, dynamic>>(
          path,
          queryParameters: params,
        );

        if (!result.isSuccess || result.data == null) {
          return (
            results: <Map<String, dynamic>>[],
            page: 1,
            totalPages: 0,
          );
        }

        final payload = result.data!;
        final rawResults = payload[resultsKey] as List<dynamic>? ?? [];
        final list = rawResults.whereType<Map<String, dynamic>>().toList();
        final page = (payload['page'] as num?)?.toInt() ?? 1;
        final totalPages = (payload['total_pages'] as num?)?.toInt() ?? page;
        final ttl = ttlMinutes ?? AppConstants.defaultCacheTTLMinutes;

        _cache.put(cacheKey, list, ttlMinutes: ttl);
        _cache.put(
          metaCacheKey,
          {'page': page, 'total_pages': totalPages},
          ttlMinutes: ttl,
        );

        return (results: list, page: page, totalPages: totalPages);
      } catch (_) {
        return (
          results: <Map<String, dynamic>>[],
          page: 1,
          totalPages: 0,
        );
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchSingle(
    String path, {
    Map<String, String>? extraParams,
    int? ttlMinutes,
    bool bypassCache = false,
  }) async {
    final params = _baseParams(extraParams);
    final cacheKey = _buildCacheKey(path, params);

    if (!bypassCache) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) return cached;
    }

    if (AppApiKey.tmdb.isEmpty) return null;

    return _dedupe(cacheKey, () async {
      if (!bypassCache) {
        final cachedAfterWait = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedAfterWait != null) return cachedAfterWait;
      }

      try {
        final result = await DioClient.instance.get<Map<String, dynamic>>(
          path,
          queryParameters: params,
        );

        if (!result.isSuccess || result.data == null) return null;

        _cache.put(
          cacheKey,
          result.data,
          ttlMinutes: ttlMinutes ?? AppConstants.defaultCacheTTLMinutes,
        );

        return result.data;
      } catch (_) {
        return null;
      }
    });
  }

  Future<T> _dedupe<T>(String key, Future<T> Function() fetch) async {
    final existing = _inflight[key];
    if (existing != null) {
      return await existing;
    }

    final completer = Completer<T>();
    _inflight[key] = completer.future;

    try {
      final result = await fetch();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    } catch (e, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(e, stackTrace);
      }
      rethrow;
    } finally {
      _inflight.remove(key);
    }
  }

  Map<String, String> _baseParams(Map<String, String>? extra) {
    return {
      'language': 'en-US',
      ...?extra,
    };
  }

  String _buildCacheKey(String path, Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    final query = sortedKeys.map((k) => '$k=${params[k]}').join('&');
    return '$path?$query';
  }
}
