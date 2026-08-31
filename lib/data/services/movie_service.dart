import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/cache/api_cache_service.dart';
import '../models/film_model.dart';

/// Service for fetching movie data from TMDB with caching
class MovieService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  final ApiCacheService _cacheService = ApiCacheService();
  
  /// Get popular movies with cache (24h TTL)
  Future<List<FilmModel>> getPopularMovies() async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'language': 'en-US',
    };
    return await _fetchAndParseList<FilmModel>('movie/popular', queryParameters: params, ttlMinutes: AppConstants.movieCacheTTL);
  }

  /// Get trending movies with cache (12h TTL)
  Future<List<FilmModel>> getTrendingMovies() async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'language': 'en-US',
    };
    return await _fetchAndParseList<FilmModel>('trending/movie/day', queryParameters: params, ttlMinutes: AppConstants.tvCacheTTL);
  }

  /// Get movie details with cache (30 days TTL)
  Future<FilmModel?> getMovieDetails({required int id}) async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
    };
    return await _fetchAndParseSingle<FilmModel>('movie/$id', queryParameters: params, ttlMinutes: AppConstants.movieDetailsCacheTTL);
  }

  /// Get cast and crew for a movie with cache (7 days TTL)
  Future<List<dynamic>> getMovieCastCrew({required int id}) async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
    };
    return await _fetchAndParseList<dynamic>('movie/$id/credits', queryParameters: params, ttlMinutes: AppConstants.movieCacheTTL);
  }

  /// Search movies by query with cache (2h TTL)
  Future<List<FilmModel>> searchMovies({required String query}) async {
    final params = <String, String>{
      'api_key': AppApiKey.tmdb,
      'query': query,
      'language': 'en-US',
    };
    return await _fetchAndParseList<FilmModel>('search/multi', queryParameters: params, ttlMinutes: AppConstants.searchCacheTTL);
  }

  /// Fetch and parse a single item
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
        print('Error fetching $path: ${result.message}');
        return null;
      }

      // Cache the response
      _cacheService.cacheManager.put(path, result.data, ttlMinutes: ttlMinutes ?? AppConstants.defaultCacheTTLMinutes);

      return result.data;
    } catch (e) {
      print('Error fetching $path: $e');
      return null;
    }
  }

  /// Fetch and parse a list of items. Returns List<T> but cast may fail if type is not correct.
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
        print('Error fetching $path: ${result.message}');
        return <T>[];
      }

      // Cache the response as List<dynamic>
      _cacheService.cacheManager.put(fullUrl, result.data);

      final items = result.data as List<dynamic>;
      return items.whereType<Map<String, dynamic>>()
          .map((e) => e as T)
          .toList();
    } catch (e) {
      print('Error fetching $path: $e');
      return <T>[];
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
