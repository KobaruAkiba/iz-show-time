import '../../core/network/dio_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_constants.dart';
import '../../core/cache/cache_manager.dart';
import '../models/catalogue_item.dart';
import '../models/episode_model.dart';
import '../models/media_details.dart';

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

  Future<List<Film>> getTrendingMovies() async {
    final results = await _fetchResults(
      'trending/movie/day',
      ttlMinutes: AppConstants.tvCacheTTL,
    );
    return results.map(Film.fromJson).toList();
  }

  Future<List<TvShow>> getTrendingTv() async {
    final results = await _fetchResults(
      'trending/tv/day',
      ttlMinutes: AppConstants.tvCacheTTL,
    );
    return results.map(TvShow.fromJson).toList();
  }

  Future<List<Film>> getPopularMovies() async {
    final results = await _fetchResults(
      'movie/popular',
      ttlMinutes: AppConstants.movieCacheTTL,
    );
    return results.map(Film.fromJson).toList();
  }

  Future<List<TvShow>> getPopularTvShows() async {
    final results = await _fetchResults(
      'tv/popular',
      ttlMinutes: AppConstants.tvCacheTTL,
    );
    return results.map(TvShow.fromJson).toList();
  }

  Future<Film?> getMovieDetails({required int id}) async {
    final data = await _fetchSingle(
      'movie/$id',
      ttlMinutes: AppConstants.movieDetailsCacheTTL,
    );
    return data == null ? null : Film.fromJson(data);
  }

  Future<TvShow?> getTvDetails({required int id}) async {
    final data = await _fetchSingle(
      'tv/$id',
      ttlMinutes: AppConstants.tvDetailsCacheTTL,
    );
    return data == null ? null : TvShow.fromJson(data);
  }

  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    final isFilm = item is Film;
    final path = isFilm ? 'movie/${item.id}' : 'tv/${item.id}';
    final data = await _fetchSingle(
      path,
      extraParams: isFilm ? {'append_to_response': 'credits'} : null,
      ttlMinutes: isFilm
          ? AppConstants.movieDetailsCacheTTL
          : AppConstants.tvDetailsCacheTTL,
    );
    if (data == null) return null;
    return MediaDetails.fromTmdbJson(data, isFilm: isFilm);
  }

  Future<({List<Film> films, List<TvShow> tvShows})> searchMulti({
    required String query,
  }) async {
    if (query.trim().isEmpty) {
      return (films: <Film>[], tvShows: <TvShow>[]);
    }

    final results = await _fetchResults(
      'search/multi',
      extraParams: {'query': query},
      ttlMinutes: AppConstants.searchCacheTTL,
    );

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

  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
  }) async {
    final results = await _fetchResults(
      'tv/$tvId/season/$seasonNumber',
      ttlMinutes: AppConstants.episodeCacheTTL,
      resultsKey: 'episodes',
    );
    return results.map(EpisodeModel.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchResults(
    String path, {
    Map<String, String>? extraParams,
    int? ttlMinutes,
    String resultsKey = 'results',
  }) async {
    final params = _baseParams(extraParams);
    final cacheKey = _buildCacheKey(path, params);

    final cached = _cache.get<List<dynamic>>(cacheKey);
    if (cached != null) {
      return cached.whereType<Map<String, dynamic>>().toList();
    }

    if (AppApiKey.tmdb.isEmpty) {
      return [];
    }

    return _dedupe(cacheKey, () async {
      final cachedAfterWait = _cache.get<List<dynamic>>(cacheKey);
      if (cachedAfterWait != null) {
        return cachedAfterWait.whereType<Map<String, dynamic>>().toList();
      }

      try {
        final result = await DioClient.instance.get<Map<String, dynamic>>(
          path,
          queryParameters: params,
        );

        if (!result.isSuccess || result.data == null) {
          return <Map<String, dynamic>>[];
        }

        final payload = result.data!;
        final rawResults = payload[resultsKey] as List<dynamic>? ?? [];
        final list = rawResults.whereType<Map<String, dynamic>>().toList();

        _cache.put(
          cacheKey,
          list,
          ttlMinutes: ttlMinutes ?? AppConstants.defaultCacheTTLMinutes,
        );

        return list;
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchSingle(
    String path, {
    Map<String, String>? extraParams,
    int? ttlMinutes,
  }) async {
    final params = _baseParams(extraParams);
    final cacheKey = _buildCacheKey(path, params);

    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    if (AppApiKey.tmdb.isEmpty) return null;

    return _dedupe(cacheKey, () async {
      final cachedAfterWait = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedAfterWait != null) return cachedAfterWait;

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
      return await existing as Future<T>;
    }

    final future = fetch();
    _inflight[key] = future;
    try {
      return await future;
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
