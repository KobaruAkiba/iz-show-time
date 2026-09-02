import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/repositories/user_data_store.dart';

class FakeUserDataStore implements UserDataStore {
  final List<CatalogueItem> savedCatalogueItems = [];
  final List<int> removedCatalogueIds = [];
  final List<WatchRecord> savedWatchRecords = [];
  final List<String> removedWatchKeys = [];
  List<NewEpisodeAlert> alerts = [];
  DateTime? lastEpisodeCheckAt;
  bool cleared = false;

  @override
  Future<void> open() async {}

  @override
  Future<List<CatalogueItem>> loadCatalogue() async => [];

  @override
  Future<void> saveCatalogueItem(CatalogueItem item) async {
    savedCatalogueItems.add(item);
  }

  @override
  Future<void> removeCatalogueItem(int mediaId) async {
    removedCatalogueIds.add(mediaId);
  }

  @override
  Future<List<WatchRecord>> loadWatchHistory() async => [];

  @override
  Future<void> saveWatchRecord(WatchRecord record) async {
    savedWatchRecords.add(record);
  }

  @override
  Future<void> removeWatchRecord(String watchKey) async {
    removedWatchKeys.add(watchKey);
  }

  @override
  Future<List<NewEpisodeAlert>> loadNewEpisodeAlerts() async =>
      List<NewEpisodeAlert>.from(alerts);

  @override
  Future<void> saveNewEpisodeAlerts(List<NewEpisodeAlert> alerts) async {
    this.alerts = List<NewEpisodeAlert>.from(alerts);
  }

  @override
  Future<DateTime?> loadLastEpisodeCheckAt() async => lastEpisodeCheckAt;

  @override
  Future<void> saveLastEpisodeCheckAt(DateTime checkedAt) async {
    lastEpisodeCheckAt = checkedAt;
  }

  @override
  Future<void> clearAll() async {
    cleared = true;
    alerts = [];
    lastEpisodeCheckAt = null;
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('AppServices persistence hooks', () {
    late AppServices appServices;
    late FakeUserDataStore store;

    setUp(() {
      appServices = AppServices();
      store = FakeUserDataStore();
      appServices.userDataStore = store;
    });

    test('addToCatalogue persists item', () async {
      const film = Film(id: 99, title: 'Persisted Film');

      await appServices.addToCatalogue(film);

      expect(store.savedCatalogueItems, [film]);
    });

    test('removeFromCatalogue persists removal', () async {
      const film = Film(id: 99, title: 'Persisted Film');
      await appServices.addToCatalogue(film);
      store.savedCatalogueItems.clear();

      await appServices.removeFromCatalogue(film.id);

      expect(store.removedCatalogueIds, [film.id]);
    });

    test('clearAllData clears store', () async {
      await appServices.clearAllData();

      expect(store.cleared, isTrue);
    });
  });
}
