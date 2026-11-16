import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/media_details.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
import 'package:iz_show_time_tracker/data/models/tv_show_summary.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/repositories/background_check_outbox.dart';
import 'package:iz_show_time_tracker/data/repositories/user_data_store.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

class FakeUserDataStore implements UserDataStore {
  final List<CatalogueItem> catalogue = [];
  final List<WatchRecord> history = [];
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
  Future<Map<String, dynamic>> exportBackupData() async => {
        'catalogue': catalogue
            .map(
              (item) => item is Film
                  ? {'type': 'film', ...item.toJson()}
                  : {'type': 'tv', ...(item as TvShow).toJson()},
            )
            .toList(),
        'watchHistory': history.map((record) => record.toJson()).toList(),
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
        'themeMode': themeMode,
      };

  @override
  Future<void> importBackupData(Map<String, dynamic> data) async {
    catalogue
      ..clear()
      ..addAll(
        (data['catalogue'] as List<dynamic>? ?? const [])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .map(
              (json) => json['type'] == 'film'
                  ? Film.fromJson(json)
                  : TvShow.fromJson(json),
            ),
      );
    history
      ..clear()
      ..addAll(
        (data['watchHistory'] as List<dynamic>? ?? const []).map((entry) =>
            WatchRecord.fromJson(Map<String, dynamic>.from(entry as Map))),
      );
    alerts = (data['alerts'] as List<dynamic>? ?? const [])
        .map((entry) =>
            NewEpisodeAlert.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
    themeMode = data['themeMode'] as String?;
  }

  @override
  Future<List<CatalogueItem>> loadCatalogue() async =>
      List<CatalogueItem>.from(catalogue);

  @override
  Future<void> saveCatalogueItem(CatalogueItem item) async {
    savedCatalogueItems.add(item);
    final index =
        catalogue.indexWhere((entry) => entry.mediaKey == item.mediaKey);
    if (index >= 0) {
      catalogue[index] = item;
    } else {
      catalogue.add(item);
    }
  }

  @override
  Future<void> removeCatalogueItem(CatalogueItem item) async {
    removedCatalogueIds.add(item.id);
    catalogue.removeWhere((entry) => entry.mediaKey == item.mediaKey);
  }

  @override
  Future<List<WatchRecord>> loadWatchHistory() async =>
      List<WatchRecord>.from(history);

  int flushCount = 0;
  int saveWatchRecordsCalls = 0;
  int removeWatchRecordsCalls = 0;

  @override
  Future<void> saveWatchRecord(WatchRecord record) async {
    await saveWatchRecords([record]);
  }

  @override
  Future<void> saveWatchRecords(Iterable<WatchRecord> records) async {
    saveWatchRecordsCalls++;
    for (final record in records) {
      history.removeWhere((entry) => entry.watchKey == record.watchKey);
      history.add(record);
      savedWatchRecords.add(record);
    }
  }

  @override
  Future<void> removeWatchRecord(String watchKey) async {
    await removeWatchRecords([watchKey]);
  }

  @override
  Future<void> removeWatchRecords(Iterable<String> watchKeys) async {
    removeWatchRecordsCalls++;
    final keys = watchKeys.toSet();
    removedWatchKeys.addAll(keys);
    history.removeWhere((record) => keys.contains(record.watchKey));
  }

  @override
  Future<void> flush() async {
    flushCount++;
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

  Set<int> notifiedEpisodeIds = {};

  @override
  Future<Set<int>> loadNotifiedEpisodeIds() async =>
      Set<int>.from(notifiedEpisodeIds);

  @override
  Future<void> saveNotifiedEpisodeIds(Set<int> episodeIds) async {
    notifiedEpisodeIds = Set<int>.from(episodeIds);
  }

  BackgroundCheckResult? backgroundCheckResult;

  @override
  Future<BackgroundCheckResult?> loadBackgroundCheckResult() async =>
      backgroundCheckResult;

  bool notificationPermissionPrePromptShown = false;

  @override
  Future<bool> loadNotificationPermissionPrePromptShown() async =>
      notificationPermissionPrePromptShown;

  @override
  Future<void> saveNotificationPermissionPrePromptShown(bool shown) async {
    notificationPermissionPrePromptShown = shown;
  }

  String? themeMode;

  @override
  Future<String?> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(String themeMode) async {
    this.themeMode = themeMode;
  }

  DateTime? lastTmdbCachePurgeAt;

  @override
  Future<DateTime?> loadLastTmdbCachePurgeAt() async => lastTmdbCachePurgeAt;

  @override
  Future<void> saveLastTmdbCachePurgeAt(DateTime purgedAt) async {
    lastTmdbCachePurgeAt = purgedAt;
  }

  @override
  Future<void> clearAll() async {
    cleared = true;
    catalogue.clear();
    history.clear();
    alerts = [];
    lastEpisodeCheckAt = null;
    notifiedEpisodeIds = {};
    notificationPermissionPrePromptShown = false;
    lastTmdbCachePurgeAt = null;
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
  Future<TvShowSummary?> getTvShowSummary(
    int tvId, {
    bool forceRefresh = false,
  }) async {
    return TvShowSummary(numberOfSeasons: seasonCount);
  }

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

/// Delays only force-refresh season fetches so a stale full refresh can
/// finish after a fast per-show refresh from markEpisodeWatched.
class DelayedStubTmdbService extends StubTmdbService {
  DelayedStubTmdbService({
    required super.seasonCount,
    required super.episodesBySeason,
    this.delay = const Duration(milliseconds: 80),
  });

  final Duration delay;
  int seasonFetchCount = 0;

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    seasonFetchCount++;
    if (forceRefresh) {
      await Future<void>.delayed(delay);
    }
    return super.getSeasonEpisodes(
      tvId: tvId,
      seasonNumber: seasonNumber,
      forceRefresh: forceRefresh,
    );
  }
}

/// Per-show episodes; shows listed in [slowShowIds] answer after a delay.
class PerShowStubTmdbService extends TmdbService {
  PerShowStubTmdbService({
    required this.episodesByShowId,
    this.slowShowIds = const {},
  }) : super(cacheManager: null);

  final Map<int, List<EpisodeModel>> episodesByShowId;
  final Set<int> slowShowIds;

  @override
  Future<TvShowSummary?> getTvShowSummary(
    int tvId, {
    bool forceRefresh = false,
  }) async {
    return const TvShowSummary(numberOfSeasons: 1);
  }

  @override
  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    return MediaDetails(title: item.title, numberOfSeasons: 1, isFilm: false);
  }

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    if (slowShowIds.contains(tvId)) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    return episodesByShowId[tvId] ?? const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      await appServices.removeFromCatalogue(film);

      expect(store.removedCatalogueIds, [film.id]);
    });

    test('toggleFavorite persists updated tags and clears on remove', () async {
      const film = Film(id: 42, title: 'Favorite Film');
      await appServices.addToCatalogue(film);
      store.savedCatalogueItems.clear();

      expect(appServices.isFavorite(film), isFalse);

      await appServices.toggleFavorite(film);

      expect(appServices.isFavorite(film), isTrue);
      expect(store.savedCatalogueItems, hasLength(1));
      expect(store.savedCatalogueItems.single.isFavorite, isTrue);
      expect(store.savedCatalogueItems.single.tags, contains(kFavoriteTag));

      await appServices.toggleFavorite(film);
      expect(appServices.isFavorite(film), isFalse);

      await appServices.toggleFavorite(film);
      store.removedCatalogueIds.clear();
      await appServices.removeFromCatalogue(film);

      expect(appServices.isFavorite(film), isFalse);
      expect(store.removedCatalogueIds, [film.id]);
    });

    test('toggleFavorite is no-op when item is not in catalogue', () async {
      const missing = Film(id: 404, title: 'Missing Film');

      await appServices.toggleFavorite(missing);

      expect(store.savedCatalogueItems, isEmpty);
      expect(appServices.isFavorite(missing), isFalse);
    });

    group('importBackgroundCheckResult', () {
      const show = TvShow(id: 77, title: 'Followed Show');

      NewEpisodeAlert alert({required int showId, required int episodeId}) {
        return NewEpisodeAlert(
          showId: showId,
          showTitle: 'Show $showId',
          episodeId: episodeId,
          seasonNumber: 1,
          episodeNumber: 2,
          episodeName: 'Episode',
          detectedAt: DateTime(2026, 5, 2),
        );
      }

      setUp(() async {
        store.catalogue.add(show.withFollowed(true));
        await appServices.initialize(userDataStore: store);
      });

      test('adopts a newer result, dropping unfollowed shows', () async {
        store.lastEpisodeCheckAt = DateTime(2026, 5, 1);
        store.backgroundCheckResult = BackgroundCheckResult(
          checkedAt: DateTime(2026, 5, 2),
          alerts: [
            alert(showId: show.id, episodeId: 701),
            alert(showId: 999, episodeId: 9991),
          ],
        );

        await appServices.importBackgroundCheckResult();

        expect(
          appServices.newEpisodeAlerts.map((entry) => entry.episodeId),
          [701],
        );
        expect(store.alerts.map((entry) => entry.episodeId), [701]);
        expect(store.lastEpisodeCheckAt, DateTime(2026, 5, 2));
      });

      test('ignores a result older than the last local check', () async {
        store.lastEpisodeCheckAt = DateTime(2026, 5, 3);
        store.backgroundCheckResult = BackgroundCheckResult(
          checkedAt: DateTime(2026, 5, 2),
          alerts: [alert(showId: show.id, episodeId: 701)],
        );

        await appServices.importBackgroundCheckResult();

        expect(appServices.newEpisodeAlerts, isEmpty);
        expect(store.lastEpisodeCheckAt, DateTime(2026, 5, 3));
      });
    });

    test('overlapping refreshes of two shows keep both next episodes',
        () async {
      await appServices.clearAllData();
      List<EpisodeModel> episodes(int showId) => [
            for (var number = 1; number <= 3; number++)
              EpisodeModel.fromJson({
                'id': showId * 10 + number,
                'season_number': 1,
                'episode_number': number,
                'name': 'E$number',
                'air_date': '2020-01-0$number',
                'runtime': 40,
              }),
          ];
      const fast = TvShow(id: 801, title: 'Fast Show');
      const slow = TvShow(id: 802, title: 'Slow Show');
      final previousTmdb = appServices.tmdbService;
      addTearDown(() => appServices.tmdbService = previousTmdb);
      appServices.tmdbService = PerShowStubTmdbService(
        episodesByShowId: {801: episodes(801), 802: episodes(802)},
        slowShowIds: {802},
      );

      await appServices.markEpisodeWatched(
        show: fast,
        episode: episodes(801)[0],
      );
      await appServices.markEpisodeWatched(
        show: slow,
        episode: episodes(802)[0],
      );

      // The slow show's refresh starts first and commits last.
      await Future.wait([
        appServices.markEpisodeWatched(show: slow, episode: episodes(802)[1]),
        appServices.markEpisodeWatched(show: fast, episode: episodes(801)[1]),
      ]);

      expect(
        appServices.newEpisodeAlerts.map((alert) => alert.episodeId).toSet(),
        {8013, 8023},
      );
    });

    test('a double tap records a film or an episode only once', () async {
      await appServices.initialize(userDataStore: store);
      const film = Film(id: 610, title: 'Double Tap Film');
      const show = TvShow(id: 611, title: 'Double Tap Show');
      final episode = EpisodeModel.fromJson({
        'id': 6111,
        'season_number': 1,
        'episode_number': 1,
        'name': 'Pilot',
        'air_date': '2020-01-01',
        'runtime': 30,
      });

      final filmResults = await Future.wait([
        appServices.markFilmWatched(film: film, durationMinutes: 100),
        appServices.markFilmWatched(film: film, durationMinutes: 100),
      ]);
      final episodeResults = await Future.wait([
        appServices.markEpisodeWatched(show: show, episode: episode),
        appServices.markEpisodeWatched(show: show, episode: episode),
      ]);

      expect(filmResults.whereType<WatchRecord>(), hasLength(1));
      expect(episodeResults.whereType<WatchRecord>(), hasLength(1));
      expect(appServices.watchHistory, hasLength(2));
      expect(appServices.totalWatchTimeMinutes, 130);
    });

    test('film and TV show sharing a TMDB id stay independent', () async {
      await appServices.initialize(userDataStore: store);
      const show = TvShow(id: 1402, title: 'Same Id Show');
      const film = Film(id: 1402, title: 'Same Id Film');
      final episodeRecord = WatchRecord(
        mediaId: show.id,
        isFilm: false,
        episodeId: 9001,
        seasonNumber: 1,
        episodeNumber: 1,
        durationMinutes: 45,
        watchedAt: DateTime(2026, 1, 1),
      );
      store.catalogue.add(show.withFollowed(true));
      store.history.add(episodeRecord);
      await appServices.initialize(userDataStore: store);

      expect(appServices.isInCatalogue(show), isTrue);
      expect(appServices.isInCatalogue(film), isFalse);
      expect(appServices.isFavorite(film), isFalse);

      await appServices.markFilmWatched(film: film, durationMinutes: 117);
      await appServices.toggleFavorite(film);

      expect(appServices.catalogue, hasLength(2));
      expect(appServices.isFavorite(film), isTrue);
      expect(appServices.isFavorite(show), isFalse);

      await appServices.removeFromCatalogue(film);

      expect(appServices.isInCatalogue(film), isFalse);
      expect(appServices.isInCatalogue(show), isTrue);
      expect(appServices.isFollowed(show.id), isTrue);
      expect(appServices.watchedEpisodesCountFor(show.id), 1);
      expect(store.history.map((record) => record.watchKey),
          [episodeRecord.watchKey]);
      expect(store.catalogue.single, isA<TvShow>());
    });

    test('addToCatalogue marks new TV shows as followed by default', () async {
      const show = TvShow(id: 55, title: 'New Show');

      await appServices.addToCatalogue(show);

      expect(appServices.isFollowed(show.id), isTrue);
      expect(store.savedCatalogueItems.single.isFollowed, isTrue);
      expect(store.savedCatalogueItems.single.tags, contains(kFollowedTag));
    });

    test('toggleFollowed persists tag and clears alerts on unfollow', () async {
      const show = TvShow(id: 77, title: 'Followed Show');
      await appServices.addToCatalogue(show);
      store.savedCatalogueItems.clear();

      expect(appServices.isFollowed(show.id), isTrue);

      final alert = NewEpisodeAlert(
        showId: show.id,
        showTitle: show.title,
        episodeId: 1,
        seasonNumber: 1,
        episodeNumber: 2,
        episodeName: 'E2',
        detectedAt: DateTime(2026, 1, 1),
      );
      appServices.updateNewEpisodeAlerts([alert]);

      await appServices.toggleFollowed(show.id);

      expect(appServices.isFollowed(show.id), isFalse);
      expect(store.savedCatalogueItems.single.isFollowed, isFalse);
      expect(appServices.newEpisodeAlerts, isEmpty);
      expect(store.alerts, isEmpty);
    });

    test('toggleFollowed is no-op for films and missing ids', () async {
      const film = Film(id: 88, title: 'Not a Show');
      await appServices.addToCatalogue(film);
      store.savedCatalogueItems.clear();

      await appServices.toggleFollowed(film.id);
      await appServices.toggleFollowed(404);

      expect(store.savedCatalogueItems, isEmpty);
      expect(appServices.isFollowed(film.id), isFalse);
      expect(appServices.isFollowed(404), isFalse);
    });

    test('clearAllData clears store', () async {
      await appServices.clearAllData();

      expect(store.cleared, isTrue);
    });

    test('export and restore backup round-trip app state', () async {
      const show = TvShow(id: 5, title: 'Backed Up Show');
      final watchedAt = DateTime(2026, 1, 10, 12);
      final alert = NewEpisodeAlert(
        showId: show.id,
        showTitle: show.title,
        episodeId: 99,
        seasonNumber: 1,
        episodeNumber: 2,
        episodeName: 'Next',
        detectedAt: watchedAt,
      );

      await appServices.addToCatalogue(show);
      await store.saveWatchRecord(
        WatchRecord(
          mediaId: show.id,
          isFilm: false,
          episodeId: 10,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 42,
          watchedAt: watchedAt,
        ),
      );
      await store.saveThemeMode('dark');
      await store.saveNewEpisodeAlerts([alert]);

      final backup = await appServices.exportUserDataBackup();

      await appServices.clearAllData();
      expect(appServices.catalogue, isEmpty);

      await appServices.restoreUserDataBackup(backup);

      expect(appServices.catalogue.map((item) => item.id), [show.id]);
      expect(appServices.watchHistory, hasLength(1));
      expect(appServices.newEpisodeAlerts, hasLength(1));
      expect(appServices.themeMode.name, 'dark');
      expect(jsonDecode(backup), isA<Map<String, dynamic>>());
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
      store.flushCount = 0;

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

        expect(appServices.isFollowed(show.id), isTrue);
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

    test(
      'marking a same-day aired Continue Watching episode clears that alert',
      () async {
        final today = DateTime.now();
        final todayIso =
            '${today.year.toString().padLeft(4, '0')}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';

        appServices.tmdbService = StubTmdbService(
          seasonCount: 1,
          episodesBySeason: {
            1: [
              EpisodeModel.fromJson({
                'id': 200,
                'season_number': 1,
                'episode_number': 1,
                'name': 'Pilot',
                'air_date': '2026-01-01',
                'runtime': 45,
              }),
              EpisodeModel.fromJson({
                'id': 201,
                'season_number': 1,
                'episode_number': 2,
                'name': 'Aired Today',
                'air_date': todayIso,
                'runtime': 45,
              }),
            ],
          },
        );

        const show = TvShow(id: 77, title: 'Same Day Show');
        final pilot = EpisodeModel.fromJson({
          'id': 200,
          'season_number': 1,
          'episode_number': 1,
          'name': 'Pilot',
          'air_date': '2026-01-01',
          'runtime': 45,
        });
        final airedToday = EpisodeModel.fromJson({
          'id': 201,
          'season_number': 1,
          'episode_number': 2,
          'name': 'Aired Today',
          'air_date': todayIso,
          'runtime': 45,
        });

        expect(airedToday.hasAired, isTrue);
        expect(EpisodeModel.isAiredToday(airedToday.airDate), isTrue);

        await appServices.addEpisodeToCatalogue(show: show, episode: pilot);
        expect(appServices.newEpisodeAlerts.single.episodeId, 201);

        await appServices.markEpisodeWatched(show: show, episode: airedToday);

        expect(
          appServices.newEpisodeAlerts.any((a) => a.episodeId == 201),
          isFalse,
        );
      },
    );

    test(
      'stale concurrent network refresh must not restore a just-watched alert',
      () async {
        final today = DateTime.now();
        final todayIso =
            '${today.year.toString().padLeft(4, '0')}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';

        final delayed = DelayedStubTmdbService(
          seasonCount: 1,
          delay: const Duration(milliseconds: 120),
          episodesBySeason: {
            1: [
              EpisodeModel.fromJson({
                'id': 300,
                'season_number': 1,
                'episode_number': 1,
                'name': 'Pilot',
                'air_date': '2026-01-01',
                'runtime': 45,
              }),
              EpisodeModel.fromJson({
                'id': 301,
                'season_number': 1,
                'episode_number': 2,
                'name': 'Aired Today',
                'air_date': todayIso,
                'runtime': 45,
              }),
            ],
          },
        );
        appServices.tmdbService = delayed;

        const show = TvShow(id: 88, title: 'Race Show');
        final pilot = EpisodeModel.fromJson({
          'id': 300,
          'season_number': 1,
          'episode_number': 1,
          'name': 'Pilot',
          'air_date': '2026-01-01',
          'runtime': 45,
        });
        final airedToday = EpisodeModel.fromJson({
          'id': 301,
          'season_number': 1,
          'episode_number': 2,
          'name': 'Aired Today',
          'air_date': todayIso,
          'runtime': 45,
        });

        await appServices.addEpisodeToCatalogue(show: show, episode: pilot);
        expect(appServices.newEpisodeAlerts.single.episodeId, 301);

        // Simulate startup/foreground force-refresh overlapping a user mark.
        final inFlight = appServices.refreshNewEpisodeAlertsFromNetwork();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await appServices.markEpisodeWatched(show: show, episode: airedToday);
        await inFlight;

        expect(
          appServices.newEpisodeAlerts.any((a) => a.episodeId == 301),
          isFalse,
          reason:
              'A slower full refresh started with a stale watch snapshot must '
              'not put the just-watched same-day episode back into Continue Watching',
        );
      },
    );

    test(
      'does not surface new episodes for catalogue shows that are not followed',
      () async {
        const show = TvShow(id: 43, title: 'Unfollowed Show');
        final episode2 = EpisodeModel.fromJson({
          'id': 100,
          'season_number': 1,
          'episode_number': 2,
          'name': 'Registered',
          'air_date': '2026-01-01',
          'runtime': 45,
        });

        await appServices.addEpisodeToCatalogue(
          show: show,
          episode: episode2,
        );
        await appServices.toggleFollowed(show.id);

        expect(appServices.isFollowed(show.id), isFalse);
        expect(appServices.newEpisodeAlerts, isEmpty);
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
      store.flushCount = 0;
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
      expect(appServices.isInCatalogue(show), isTrue);
      expect(appServices.tvShows, hasLength(1));
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
      expect(store.saveWatchRecordsCalls, 1);
      expect(store.flushCount, 1);
    });

    test('uses the season average for an aired episode without runtime',
        () async {
      const show = TvShow(id: 71, title: 'Airing Soon Show');
      final ready = EpisodeModel.fromJson({
        'id': 211,
        'season_number': 1,
        'episode_number': 1,
        'name': 'Ready',
        'air_date': '2020-01-01',
        'runtime': 42,
      });
      final airingSoon = EpisodeModel.fromJson({
        'id': 212,
        'season_number': 1,
        'episode_number': 2,
        'name': 'No Runtime',
        'air_date': '2020-01-08',
      });

      expect(airingSoon.isAiringSoon(), isTrue);

      final addedCount = await appServices.addSeasonToCatalogue(
        show: show,
        episodes: [ready, airingSoon],
      );

      expect(addedCount, 2);
      expect(
        appServices.isWatched(mediaId: show.id, episodeId: ready.id),
        isTrue,
      );
      final fallbackRecord = appServices.watchedEpisodesFor(show.id).firstWhere(
            (record) => record.episodeId == airingSoon.id,
          );
      expect(fallbackRecord.durationMinutes, 42);
    });

    test('skips airing-soon episodes when no runtime can be resolved',
        () async {
      const show = TvShow(id: 72, title: 'No Runtime Show');
      final episodes = [
        for (var number = 1; number <= 2; number++)
          EpisodeModel.fromJson({
            'id': 220 + number,
            'season_number': 1,
            'episode_number': number,
            'name': 'No Runtime $number',
            'air_date': '2020-01-0$number',
          }),
      ];

      final addedCount = await appServices.addSeasonToCatalogue(
        show: show,
        episodes: episodes,
      );

      expect(addedCount, 0);
      expect(appServices.isInCatalogue(show), isFalse);
    });

    test('persists a season in one batch write and one flush', () async {
      const show = TvShow(id: 8, title: 'Batch Show');
      final episodes = List.generate(
        20,
        (index) => EpisodeModel.fromJson({
          'id': 300 + index,
          'season_number': 1,
          'episode_number': index + 1,
          'name': 'E${index + 1}',
          'air_date': '2020-01-01',
          'runtime': 40,
        }),
      );

      final addedCount = await appServices.addSeasonToCatalogue(
        show: show,
        episodes: episodes,
      );

      expect(addedCount, 20);
      expect(appServices.isInCatalogue(show), isTrue);
      expect(store.savedWatchRecords, hasLength(20));
      expect(store.saveWatchRecordsCalls, 1);
      expect(store.flushCount, 1);
    });

    test('does not add show when no episodes can be catalogued', () async {
      const show = TvShow(id: 9, title: 'Empty Season Show');
      final upcoming = EpisodeModel.fromJson({
        'id': 401,
        'season_number': 1,
        'episode_number': 1,
        'name': 'Upcoming',
        'air_date': '2099-06-01',
        'runtime': 42,
      });

      final addedCount = await appServices.addSeasonToCatalogue(
        show: show,
        episodes: [upcoming],
      );

      expect(addedCount, 0);
      expect(appServices.isInCatalogue(show), isFalse);
      expect(store.savedCatalogueItems, isEmpty);
    });

    test(
      'adding a full season surfaces the next season premiere in alerts',
      () async {
        const show = TvShow(id: 10, title: 'Multi Season Show');
        final seasonOne = [
          EpisodeModel.fromJson({
            'id': 501,
            'season_number': 1,
            'episode_number': 1,
            'name': 'Pilot',
            'air_date': '2020-01-01',
            'runtime': 42,
          }),
          EpisodeModel.fromJson({
            'id': 502,
            'season_number': 1,
            'episode_number': 2,
            'name': 'Finale',
            'air_date': '2020-01-08',
            'runtime': 42,
          }),
        ];

        appServices.tmdbService = StubTmdbService(
          seasonCount: 2,
          episodesBySeason: {
            1: seasonOne,
            2: [
              EpisodeModel.fromJson({
                'id': 601,
                'season_number': 2,
                'episode_number': 1,
                'name': 'Premiere',
                'air_date': '2020-02-01',
                'runtime': 42,
              }),
            ],
          },
        );

        final addedCount = await appServices.addSeasonToCatalogue(
          show: show,
          episodes: seasonOne,
        );

        expect(addedCount, 2);
        expect(appServices.isFollowed(show.id), isTrue);
        expect(appServices.newEpisodeAlerts, hasLength(1));
        expect(appServices.newEpisodeAlerts.first.seasonNumber, 2);
        expect(appServices.newEpisodeAlerts.first.episodeNumber, 1);
        expect(appServices.newEpisodeAlerts.first.episodeId, 601);
      },
    );

    test(
      'does not re-follow when adding a season to an unfollowed show',
      () async {
        const show = TvShow(id: 11, title: 'Unfollowed Multi');
        await appServices.addToCatalogue(show);
        await appServices.toggleFollowed(show.id);
        expect(appServices.isFollowed(show.id), isFalse);

        final seasonOne = [
          EpisodeModel.fromJson({
            'id': 701,
            'season_number': 1,
            'episode_number': 1,
            'name': 'Pilot',
            'air_date': '2020-01-01',
            'runtime': 42,
          }),
        ];

        appServices.tmdbService = StubTmdbService(
          seasonCount: 2,
          episodesBySeason: {
            1: seasonOne,
            2: [
              EpisodeModel.fromJson({
                'id': 801,
                'season_number': 2,
                'episode_number': 1,
                'name': 'Premiere',
                'air_date': '2020-02-01',
                'runtime': 42,
              }),
            ],
          },
        );

        await appServices.addSeasonToCatalogue(
          show: show,
          episodes: seasonOne,
        );

        expect(appServices.isFollowed(show.id), isFalse);
        expect(appServices.newEpisodeAlerts, isEmpty);
      },
    );
  });

  group('AppServices addEpisodeToCatalogue', () {
    late AppServices appServices;
    late FakeUserDataStore store;

    setUp(() async {
      appServices = AppServices();
      store = FakeUserDataStore();
      appServices.userDataStore = store;
      await appServices.clearAllData();
      store.cleared = false;
      store.flushCount = 0;
    });

    test('adds the show to catalogue when an episode is added', () async {
      const show = TvShow(id: 50, title: 'Catalogue Show');
      final episode = EpisodeModel.fromJson({
        'id': 501,
        'season_number': 1,
        'episode_number': 1,
        'name': 'Pilot',
        'air_date': '2020-01-01',
        'runtime': 45,
      });

      expect(appServices.isInCatalogue(show), isFalse);

      final record = await appServices.addEpisodeToCatalogue(
        show: show,
        episode: episode,
      );

      expect(record, isNotNull);
      expect(appServices.isInCatalogue(show), isTrue);
      expect(appServices.tvShows.single.id, show.id);
      expect(store.savedCatalogueItems.single.id, show.id);
      expect(
        appServices.isWatched(mediaId: show.id, episodeId: episode.id),
        isTrue,
      );
    });

    test('does not add show when episode runtime is unavailable', () async {
      const show = TvShow(id: 51, title: 'No Runtime Show');
      final episode = EpisodeModel.fromJson({
        'id': 502,
        'season_number': 1,
        'episode_number': 1,
        'name': 'Pilot',
        'air_date': '2020-01-01',
      });

      final record = await appServices.addEpisodeToCatalogue(
        show: show,
        episode: episode,
      );

      expect(record, isNull);
      expect(appServices.isInCatalogue(show), isFalse);
      expect(store.savedCatalogueItems, isEmpty);
    });
  });

  group('AppServices wouldRemoveLastCataloguedEpisodes', () {
    late AppServices appServices;
    late FakeUserDataStore store;

    setUp(() async {
      appServices = AppServices();
      store = FakeUserDataStore();
      appServices.userDataStore = store;
      await appServices.clearAllData();
      store.cleared = false;
      store.flushCount = 0;
    });

    test('is false for bookmark-only shows with no episodes', () async {
      const show = TvShow(id: 60, title: 'Bookmarked Show');
      await appServices.addToCatalogue(show);

      expect(
        appServices.wouldRemoveLastCataloguedEpisodes(
          mediaId: show.id,
          episodeIds: const [999],
        ),
        isFalse,
      );
    });

    test('is true when removing the only catalogued episode', () async {
      const show = TvShow(id: 61, title: 'Single Episode Show');
      final episode = EpisodeModel.fromJson({
        'id': 601,
        'season_number': 1,
        'episode_number': 1,
        'name': 'Pilot',
        'air_date': '2020-01-01',
        'runtime': 45,
      });
      await appServices.addEpisodeToCatalogue(show: show, episode: episode);

      expect(
        appServices.wouldRemoveLastCataloguedEpisodes(
          mediaId: show.id,
          episodeIds: [episode.id],
        ),
        isTrue,
      );
    });

    test('is false when other catalogued episodes would remain', () async {
      const show = TvShow(id: 62, title: 'Two Episode Show');
      final episode1 = EpisodeModel.fromJson({
        'id': 701,
        'season_number': 1,
        'episode_number': 1,
        'name': 'One',
        'air_date': '2020-01-01',
        'runtime': 45,
      });
      final episode2 = EpisodeModel.fromJson({
        'id': 702,
        'season_number': 1,
        'episode_number': 2,
        'name': 'Two',
        'air_date': '2020-01-08',
        'runtime': 45,
      });
      await appServices.addEpisodeToCatalogue(show: show, episode: episode1);
      await appServices.addEpisodeToCatalogue(show: show, episode: episode2);

      expect(
        appServices.wouldRemoveLastCataloguedEpisodes(
          mediaId: show.id,
          episodeIds: [episode1.id],
        ),
        isFalse,
      );
      expect(
        appServices.wouldRemoveLastCataloguedEpisodes(
          mediaId: show.id,
          episodeIds: [episode1.id, episode2.id],
        ),
        isTrue,
      );
    });
  });

  group('AppServices TMDB cache compliance purge', () {
    late AppServices appServices;
    late FakeUserDataStore store;

    setUp(() {
      appServices = AppServices();
      store = FakeUserDataStore();
      appServices.userDataStore = store;
      appServices.cacheManager.clearAll();
    });

    tearDown(() {
      appServices.cacheManager.clearAll();
    });

    test('initialize stamps purge time when missing', () async {
      expect(store.lastTmdbCachePurgeAt, isNull);

      await appServices.initialize(userDataStore: store);

      expect(store.lastTmdbCachePurgeAt, isNotNull);
    });

    test('initialize purges when last purge is older than max age', () async {
      final stale = DateTime.now().toUtc().subtract(
            const Duration(days: 200),
          );
      store.lastTmdbCachePurgeAt = stale;
      appServices.cacheManager.put('tmdb:stale', {'ok': true}, ttlMinutes: 60);
      expect(appServices.cacheManager.get<Map<String, dynamic>>('tmdb:stale'), isNotNull);

      await appServices.initialize(userDataStore: store);

      expect(appServices.cacheManager.get<Map<String, dynamic>>('tmdb:stale'), isNull);
      expect(store.lastTmdbCachePurgeAt!.isAfter(stale), isTrue);
      expect(appServices.catalogue, isEmpty);
    });

    test('initialize skips purge when last purge is recent', () async {
      final recent = DateTime.now().toUtc().subtract(const Duration(days: 30));
      store.lastTmdbCachePurgeAt = recent;
      appServices.cacheManager.put('tmdb:fresh', {'ok': true}, ttlMinutes: 60);

      await appServices.initialize(userDataStore: store);

      expect(appServices.cacheManager.get<Map<String, dynamic>>('tmdb:fresh'), isNotNull);
      expect(store.lastTmdbCachePurgeAt, recent);
    });

    test('clearCacheData keeps catalogue and updates purge stamp', () async {
      await appServices.initialize(userDataStore: store);
      await appServices.addToCatalogue(
        const Film(
          id: 1,
          title: 'Kept',
          posterPath: '/p.jpg',
          voteAverage: 8,
        ),
      );
      appServices.cacheManager.put('tmdb:x', 1, ttlMinutes: 60);
      final before = store.lastTmdbCachePurgeAt!;

      await Future<void>.delayed(const Duration(milliseconds: 2));
      await appServices.clearCacheData();

      expect(appServices.cacheManager.get<dynamic>('tmdb:x'), isNull);
      expect(
        appServices.isInCatalogue(const Film(id: 1, title: 'Kept')),
        isTrue,
      );
      expect(store.lastTmdbCachePurgeAt!.isAfter(before), isTrue);
    });
  });
}
