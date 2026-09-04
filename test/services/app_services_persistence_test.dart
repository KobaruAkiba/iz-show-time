import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/media_details.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/repositories/user_data_store.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

class FakeUserDataStore implements UserDataStore {
  final List<CatalogueItem> savedCatalogueItems = [];
  final List<int> removedCatalogueIds = [];
  final List<WatchRecord> savedWatchRecords = [];
  final List<String> removedWatchKeys = [];
  List<NewEpisodeAlert> alerts = [];
  DateTime? lastEpisodeCheckAt;
  bool appInForeground = false;
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
  Future<bool> loadAppInForeground() async => appInForeground;

  @override
  Future<void> saveAppInForeground(bool isInForeground) async {
    appInForeground = isInForeground;
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

class StubTmdbService extends TmdbService {
  StubTmdbService({
    required this.seasonCount,
    required this.episodesBySeason,
  }) : super(cacheManager: null);

  final int seasonCount;
  final Map<int, List<EpisodeModel>> episodesBySeason;

  @override
  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    return MediaDetails(
      title: item.title,
      numberOfSeasons: seasonCount,
      isFilm: false,
    );
  }

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    return episodesBySeason[seasonNumber] ?? const [];
  }
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

    test('toggleFavorite persists updated tags and clears on remove', () async {
      const film = Film(id: 42, title: 'Favorite Film');
      await appServices.addToCatalogue(film);
      store.savedCatalogueItems.clear();

      expect(appServices.isFavorite(film.id), isFalse);

      await appServices.toggleFavorite(film.id);

      expect(appServices.isFavorite(film.id), isTrue);
      expect(store.savedCatalogueItems, hasLength(1));
      expect(store.savedCatalogueItems.single.isFavorite, isTrue);
      expect(store.savedCatalogueItems.single.tags, contains(kFavoriteTag));

      await appServices.toggleFavorite(film.id);
      expect(appServices.isFavorite(film.id), isFalse);

      await appServices.toggleFavorite(film.id);
      store.removedCatalogueIds.clear();
      await appServices.removeFromCatalogue(film.id);

      expect(appServices.isFavorite(film.id), isFalse);
      expect(store.removedCatalogueIds, [film.id]);
    });

    test('toggleFavorite is no-op when item is not in catalogue', () async {
      await appServices.toggleFavorite(404);

      expect(store.savedCatalogueItems, isEmpty);
      expect(appServices.isFavorite(404), isFalse);
    });

    test('clearAllData clears store', () async {
      await appServices.clearAllData();

      expect(store.cleared, isTrue);
    });
  });

  group('AppServices new episode alerts after watch changes', () {
    late AppServices appServices;
    late FakeUserDataStore store;

    setUp(() async {
      appServices = AppServices();
      store = FakeUserDataStore();
      appServices.userDataStore = store;
      await appServices.clearAllData();
      store.cleared = false;

      appServices.tmdbService = StubTmdbService(
        seasonCount: 1,
        episodesBySeason: {
          1: [
            EpisodeModel.fromJson({
              'id': 100,
              'season_number': 1,
              'episode_number': 2,
              'name': 'Registered',
              'air_date': '2026-01-01',
              'runtime': 45,
            }),
            EpisodeModel.fromJson({
              'id': 101,
              'season_number': 1,
              'episode_number': 3,
              'name': 'Next Aired',
              'air_date': '2026-01-08',
              'runtime': 45,
            }),
            EpisodeModel.fromJson({
              'id': 102,
              'season_number': 1,
              'episode_number': 4,
              'name': 'Following Aired',
              'air_date': '2026-01-15',
              'runtime': 45,
            }),
          ],
        },
      );
    });

    test(
      'marking an episode watched immediately surfaces the next aired episode',
      () async {
        const show = TvShow(id: 42, title: 'Sample Show');
        final episode2 = EpisodeModel.fromJson({
          'id': 100,
          'season_number': 1,
          'episode_number': 2,
          'name': 'Registered',
          'air_date': '2026-01-01',
          'runtime': 45,
        });
        final episode3 = EpisodeModel.fromJson({
          'id': 101,
          'season_number': 1,
          'episode_number': 3,
          'name': 'Next Aired',
          'air_date': '2026-01-08',
          'runtime': 45,
        });

        await appServices.addEpisodeToCatalogue(
          show: show,
          episode: episode2,
        );

        expect(appServices.newEpisodeAlerts, hasLength(1));
        expect(appServices.newEpisodeAlerts.first.episodeId, 101);
        expect(appServices.newEpisodeAlerts.first.episodeNumber, 3);

        await appServices.markEpisodeWatched(
          show: show,
          episode: episode3,
        );

        expect(appServices.newEpisodeAlerts, hasLength(1));
        expect(appServices.newEpisodeAlerts.first.episodeId, 102);
        expect(appServices.newEpisodeAlerts.first.episodeNumber, 4);
      },
    );
  });

  group('AppServices addSeasonToCatalogue', () {
    late AppServices appServices;
    late FakeUserDataStore store;

    setUp(() async {
      appServices = AppServices();
      store = FakeUserDataStore();
      appServices.userDataStore = store;
      await appServices.clearAllData();
      store.cleared = false;
    });

    test('skips upcoming episodes and still adds undated ones', () async {
      const show = TvShow(id: 7, title: 'In Progress Show');
      final aired = EpisodeModel.fromJson({
        'id': 201,
        'season_number': 1,
        'episode_number': 1,
        'name': 'Aired',
        'air_date': '2020-01-01',
        'runtime': 42,
      });
      final undated = EpisodeModel.fromJson({
        'id': 202,
        'season_number': 1,
        'episode_number': 2,
        'name': 'Missing air date',
        'runtime': 42,
      });
      final upcoming = EpisodeModel.fromJson({
        'id': 203,
        'season_number': 1,
        'episode_number': 3,
        'name': 'Upcoming',
        'air_date': '2099-06-01',
        'runtime': 42,
      });

      expect(aired.isUpcoming, isFalse);
      expect(undated.isUpcoming, isFalse);
      expect(undated.hasAired, isFalse);
      expect(upcoming.isUpcoming, isTrue);

      final addedCount = await appServices.addSeasonToCatalogue(
        show: show,
        episodes: [aired, undated, upcoming],
      );

      expect(addedCount, 2);
      expect(
        appServices.isWatched(mediaId: show.id, episodeId: aired.id),
        isTrue,
      );
      expect(
        appServices.isWatched(mediaId: show.id, episodeId: undated.id),
        isTrue,
      );
      expect(
        appServices.isWatched(mediaId: show.id, episodeId: upcoming.id),
        isFalse,
      );
      expect(store.savedWatchRecords, hasLength(2));
      expect(
        store.savedWatchRecords.map((record) => record.episodeId),
        [aired.id, undated.id],
      );
    });
  });
}
