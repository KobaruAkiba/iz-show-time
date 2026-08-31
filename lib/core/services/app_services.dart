import '../cache/cache_manager.dart';
import '../cache/api_cache_service.dart';
import '../background/background_task_runner.dart';
import '../../data/services/tmdb_service.dart';
import '../../data/models/catalogue_item.dart';

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

  List<CatalogueItem> get catalogue => List.unmodifiable(_catalogue);

  List<Film> get films =>
      _catalogue.whereType<Film>().toList(growable: false);

  List<TvShow> get tvShows =>
      _catalogue.whereType<TvShow>().toList(growable: false);

  bool isInCatalogue(int id) => _catalogue.any((item) => item.id == id);

  void addToCatalogue(CatalogueItem item) {
    if (isInCatalogue(item.id)) return;
    _catalogue.add(item);
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
    };
  }

  Future<void> clearAllData() async {
    cacheManager.clearAll();
    _catalogue.clear();
  }
}
