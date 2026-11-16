import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../cache/tmdb_disk_cache.dart';
import '../config/api_key_config.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../services/app_services.dart';

/// Shared Hive / network / services setup for UI and background isolates.
class AppBootstrap {
  AppBootstrap._();

  static Future<AppServices> initializeServices() async {
    await initializePlatform();

    final appServices = AppServices()
      ..imageDiskCachePurge = DefaultCacheManager().emptyCache
      ..tmdbDiskCache = await _openTmdbDiskCache();
    await appServices.initialize();
    return appServices;
  }

  /// The app works without it, so a failure to open is not fatal.
  static Future<TmdbDiskCache?> _openTmdbDiskCache() async {
    try {
      final cache = await TmdbDiskCache.open();
      unawaited(cache.trim());
      return cache;
    } catch (error, stackTrace) {
      debugPrint('TMDB disk cache unavailable: $error\n$stackTrace');
      return null;
    }
  }

  /// Hive path and TMDB client, without opening any user data.
  static Future<void> initializePlatform() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Hive.initFlutter();
    } catch (error, stackTrace) {
      debugPrint('Hive.initFlutter failed: $error\n$stackTrace');
      rethrow;
    }

    final apiKey = resolveTmdbApiKey();
    AppApiKey.configure(apiKey);
    await DioClient.init(apiKey: apiKey);
  }
}
