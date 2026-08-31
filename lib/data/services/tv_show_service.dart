import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/cache/api_cache_service.dart';
import '../models/tv_show_model.dart';
import '../models/episode_model.dart';

/// Service for fetching TV show data from TMDB with caching
class TvShowService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  final ApiCacheService _cacheService = ApiCacheService();

  /// Get popular TV shows with cache (24h TTL)
  Future<List<TvShowModel>> getPopularTvShows() async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'language': 'en-US',
    };
    return await _fetchAndParseList<TvShowModel>('tv/popular', queryParameters: params, ttlMinutes: AppConstants.tvCacheTTL);
  }

  /// Get trending TV shows with cache (12h TTL)
  Future<List<TvShowModel>> getTrendingTvShows() async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'language': 'en-US',
    };
    return await _fetchAndParseList<TvShowModel>('trending/tv/day', queryParameters: params, ttlMinutes: AppConstants.tvCacheTTL);
  }

  /// Get TV show details with cache (30 days TTL)
  Future<TvShowModel?> getTvShowDetails(int tvId) async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'language': 'en-US',
    };
    return await _fetchAndParseSingle<TvShowModel>('tv/$tvId', queryParameters: params, ttlMinutes: AppConstants.tvDetailsCacheTTL);
  }

  /// Search for TV shows with cache (2h TTL)
  Future<List<dynamic>> searchTvShows(String query, {int page = 1}) async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'q': query,
      'page': page.toString(),
      'language': 'en-US',
      'include_adult': 'false',
    };
    return await _fetchAndParseList<dynamic>('search/multi', queryParameters: params, ttlMinutes: AppConstants.searchCacheTTL);
  }

  /// Get all episodes for a TV show season with cache (24h TTL - can change daily)
  Future<List<EpisodeModel>> getTvShowEpisodes(int tvId, int seasonNumber) async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'tv_id': tvId.toString(),
      'season_number': seasonNumber.toString(),
    };
    return await _fetchAndParseList<EpisodeModel>('tv/$tvId/season/$seasonNumber', queryParameters: params, ttlMinutes: AppConstants.episodeCacheTTL);
  }

  /// Get specific episode details with cache (daily refresh)
  Future<EpisodeModel?> getEpisodeDetails(int tvId, int seasonNumber, int episodeNumber) async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'tv_id': tvId.toString(),
      'season_number': seasonNumber.toString(),
      'episode_number': episodeNumber.toString(),
    };
    return await _fetchAndParseSingle<EpisodeModel>('tv/$tvId/season/$seasonNumber/episode/$episodeNumber', queryParameters: params, ttlMinutes: AppConstants.episodeCacheTTL);
  }

  /// Generic fetch and parse method for list results
  Future<List<T>> _fetchAndParseList<T>(String path, {Map<String, dynamic>? queryParameters, int? ttlMinutes}) async {
    // Check cache first - use a cache key that includes query parameters
    final fullUrl = _buildFullUrl(path, queryParameters: queryParameters);
    final cached = _cacheService.cacheManager.get<List<dynamic>>(fullUrl);
    if (cached != null) {
      // Return cached data with proper type conversion
      return List<T>.from(cached);
    }

    try {
      // Fetch from API using the configured DioClient with query parameters
      final result = await DioClient.instance.get<T>(path, queryParameters: queryParameters);

      if (!result.isSuccess) {
        print('Error fetching list from $path: ${result.message}');
        return <T>[];
      }

      // Cache the response as List<dynamic>
      _cacheService.cacheManager.put(fullUrl, result.data);

      final items = result.data as List<dynamic>;
      return items.whereType<Map<String, dynamic>>()
          .map((e) => e as T)
          .toList();
    } catch (e) {
      print('Error fetching list from $path: $e');
      return <T>[];
    }
  }

  /// Fetch and parse single item
  Future<T?> _fetchAndParseSingle<T>(String path, {Map<String, dynamic>? queryParameters, int? ttlMinutes}) async {
    // Check cache first
    final cached = _cacheService.cacheManager.get<T>(path);
    if (cached != null) {
      return cached;
    }

    try {
      // Fetch from API using the configured DioClient with query parameters
      final result = await DioClient.instance.get<T>(path, queryParameters: queryParameters);

      if (!result.isSuccess) {
        print('Error fetching details from $path: ${result.message}');
        return null;
      }

      // Cache the response
      _cacheService.cacheManager.put(path, result.data, ttlMinutes: ttlMinutes ?? AppConstants.defaultCacheTTLMinutes);

      return result.data;
    } catch (e) {
      print('Error fetching details from $path: $e');
      return null;
    }
  }

  /// Build full URL with query parameters for caching
  String _buildFullUrl(String path, {Map<String, dynamic>? queryParameters}) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return '$_baseUrl/$path';
    }
    final paramsString = queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$_baseUrl/$path?$paramsString';
  }
}
