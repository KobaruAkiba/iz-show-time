import 'package:flutter/foundation.dart';

/// Media type enum for API requests
enum MediaType { movie, tvShow }

/// API Configuration and Endpoints for TMDB integration
class ApiConstants {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  static const String originalImage = '/original';
  static const String w500Image = '/w500';
  static const String w342Image = '/w342';

  static String posterUrl(String? path, {String size = w500Image}) {
    if (path == null || path.isEmpty) return '';
    return '$imageBaseUrl$size$path';
  }
}

/// API Key management class
class AppApiKey {
  static String _key = '';

  static String get tmdb {
    if (_key.isNotEmpty) return _key;
    const envKey = String.fromEnvironment('TMDB_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    if (kDebugMode) {
      const devKey = String.fromEnvironment(
        'DEV_TMDB_API_KEY',
        defaultValue: '',
      );
      if (devKey.isNotEmpty) return devKey;
    }
    return '';
  }

  static void configure(String key) => _key = key;

  static void setDevKey(String key) {
    if (kDebugMode) _key = key;
  }

  static void setProdKey(String key) => _key = key;
}
