import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/new_episode_checker.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/media_details.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/repositories/user_data_store.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

class FakeEpisodeCheckStore implements UserDataStore {
  List<NewEpisodeAlert> alerts = [];
  DateTime? lastCheck;

  @override
  Future<void> open() async {}

  @override
  Future<List<CatalogueItem>> loadCatalogue() async => [];

  @override
  Future<void> saveCatalogueItem(CatalogueItem item) async {}

  @override
  Future<void> removeCatalogueItem(int mediaId) async {}

  @override
  Future<List<WatchRecord>> loadWatchHistory() async => [];

  @override
  Future<void> saveWatchRecord(WatchRecord record) async {}

  @override
  Future<void> removeWatchRecord(String watchKey) async {}

  @override
  Future<List<NewEpisodeAlert>> loadNewEpisodeAlerts() async =>
      List<NewEpisodeAlert>.from(alerts);

  @override
  Future<void> saveNewEpisodeAlerts(List<NewEpisodeAlert> alerts) async {
    this.alerts = List<NewEpisodeAlert>.from(alerts);
  }

  @override
  Future<DateTime?> loadLastEpisodeCheckAt() async => lastCheck;

  @override
  Future<void> saveLastEpisodeCheckAt(DateTime checkedAt) async {
    lastCheck = checkedAt;
  }

  @override
  Future<void> clearAll() async {
    alerts = [];
    lastCheck = null;
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
  group('NewEpisodeChecker', () {
    late FakeEpisodeCheckStore store;

    setUp(() {
      store = FakeEpisodeCheckStore();
    });

    test('creates alerts for aired episodes after last registered S/E', () async {
      const show = TvShow(id: 42, title: 'Sample Show');
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
          mediaTitle: 'Sample Show',
          isFilm: false,
          episodeId: 100,
          seasonNumber: 1,
          episodeNumber: 2,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      final tmdb = StubTmdbService(
        seasonCount: 1,
        episodesBySeason: {
          1: [
            EpisodeModel.fromJson({
              'id': 100,
              'season_number': 1,
              'episode_number': 2,
              'name': 'Registered',
              'air_date': '2026-01-01',
            }),
            EpisodeModel.fromJson({
              'id': 101,
              'season_number': 1,
              'episode_number': 3,
              'name': 'New One',
              'air_date': '2026-01-08',
            }),
          ],
        },
      );

      final checker = NewEpisodeChecker(
        tmdbService: tmdb,
        userDataStore: store,
      );

      final result = await checker.checkShows(
        shows: [show],
        watchHistory: watchHistory,
      );

      expect(result.newlyDetected, hasLength(1));
      expect(result.newlyDetected.first.episodeNumber, 3);
      expect(result.allAlerts, hasLength(1));
    });

    test('skips shows without a registered episode in catalogue', () async {
      const show = TvShow(id: 42, title: 'Sample Show');
      final tmdb = StubTmdbService(
        seasonCount: 1,
        episodesBySeason: {
          1: [
            EpisodeModel.fromJson({
              'id': 101,
              'season_number': 1,
              'episode_number': 1,
              'name': 'Pilot',
              'air_date': '2026-01-01',
            }),
          ],
        },
      );

      final checker = NewEpisodeChecker(
        tmdbService: tmdb,
        userDataStore: store,
      );

      final result = await checker.checkShows(
        shows: [show],
        watchHistory: const [],
      );

      expect(result.newlyDetected, isEmpty);
      expect(result.allAlerts, isEmpty);
    });
  });
}
