import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Media type enum for API requests
enum MediaType { movie, tv_show }

/// API Configuration and Endpoints for TMDB integration
class ApiConstants {
  // Base URL - Set this in your actual implementation with your API key
  static const String baseUrl = 'https://api.themoviedb.org/3';
  
  // Image endpoints
  static const String originalImage = '/original';
  static const String w500Image = '/w500';
  static const String w342Image = '/w342';
}

/// API Key management class
class AppApiKey {
  // These should be loaded from environment variables or config files in production
  static String _devKey = '';
  static String _prodKey = '';
  
  /// Get TMDB API key - loads from environment if available, otherwise falls back to stored keys
  static String get tmdb {
    // Check for environment variable (production builds)
    final envKey = String.fromEnvironment('TMDB_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // For debug mode, use stored dev key
    if (kDebugMode) {
      _devKey ??= String.fromEnvironment('DEV_TMDB_API_KEY', defaultValue: 'YOUR_DEV_API_KEY_HERE');
      return _devKey.isNotEmpty ? _devKey : 'YOUR_DEV_API_KEY_HERE';
    } else {
      _prodKey ??= String.fromEnvironment('TMDB_API_KEY', defaultValue: 'YOUR_PROD_API_KEY_HERE');
      return _prodKey.isNotEmpty ? _prodKey : 'YOUR_PROD_API_KEY_HERE';
    }
  }
  
  /// Method to override the API key for testing (dev mode only)
  static void setApiKey(String key) {
    if (kDebugMode) {
      _devKey = key;
    } else {
      _prodKey = key;
    }
  }
  
  /// Set development API key
  static void setDevKey(String key) => _devKey = key;
  
  /// Set production API key
  static void setProdKey(String key) => _prodKey = key;
}

/// Helper to get environment variable (useful for reading from .env files)
class Env {
  /// Get an environment variable value
  static String? get(String key) {
    final envValue = Platform.environment[key];
    return envValue;
  }
  
  // Convenience getters
  static String? get tmdbApiKey => get('TMDB_API_KEY');
  static String? get devTmdbApiKey => get('DEV_TMDB_API_KEY');
  
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isMacOS => Platform.isMacOS;
}
