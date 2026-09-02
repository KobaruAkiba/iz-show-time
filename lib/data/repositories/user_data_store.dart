import '../models/catalogue_item.dart';
import '../models/watch_record.dart';

/// Persists catalogue items and watch history on device.
abstract class UserDataStore {
  Future<void> open();

  Future<List<CatalogueItem>> loadCatalogue();

  Future<void> saveCatalogueItem(CatalogueItem item);

  Future<void> removeCatalogueItem(int mediaId);

  Future<List<WatchRecord>> loadWatchHistory();

  Future<void> saveWatchRecord(WatchRecord record);

  Future<void> removeWatchRecord(String watchKey);

  Future<void> clearAll();

  Future<void> close();
}
