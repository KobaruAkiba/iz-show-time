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
  bool appInForeground = false;

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
  Future<void> saveWatchRecords(Iterable<WatchRecord> records) async {}

  @override
  Future<void> removeWatchRecord(String watchKey) async {}

  @override
  Future<void> removeWatchRecords(Iterable<String> watchKeys) async {}

  @override
  Future<void> flush() async {}

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
    alerts = [];
    lastCheck = null;
    notifiedEpisodeIds = {};
    notificationPermissionPrePromptShown = false;
    lastTmdbCachePurgeAt = null;
  }

  @override
  Future<Map<String, dynamic>> exportBackupData() async => {
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
      };

  @override
  Future<void> importBackupData(Map<String, dynamic> data) async {}

  @override
  Future<void> close() async {}
}

class StubTmdbService extends TmdbService {
  StubTmdbService({
    required this.seasonCount,
    required this.episodesBySeason,
    this.detailsStatus,
    this.detailsNextEpisodeAirDate,
    this.detailsPosterPath,
    this.averageEpisodeRuntimeMinutes = 45,
  }) : super(cacheManager: null);

  final int seasonCount;
  final Map<int, List<EpisodeModel>> episodesBySeason;
  final String? detailsStatus;
  final String? detailsNextEpisodeAirDate;
  final String? detailsPosterPath;
  final int? averageEpisodeRuntimeMinutes;
  int seasonFetchCount = 0;

  @override
  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    return MediaDetails(
      title: item.title,
      numberOfSeasons: seasonCount,
      isFilm: false,
      status: detailsStatus,
      nextEpisodeAirDate: detailsNextEpisodeAirDate,
      posterPath: detailsPosterPath,
      averageEpisodeRuntimeMinutes: averageEpisodeRuntimeMinutes,
    );
  }

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    seasonFetchCount++;
    return episodesBySeason[seasonNumber] ?? const [];
  }
}

/// Per-show episode stubs for multi-show sort tests.
class MultiShowStubTmdbService extends TmdbService {
  MultiShowStubTmdbService({required this.byShowId})
      : super(cacheManager: null);

  final Map<
      int,
      ({
        int seasonCount,
        Map<int, List<EpisodeModel>> episodesBySeason,
      })> byShowId;

  @override
  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    final data = byShowId[item.id]!;
    return MediaDetails(
      title: item.title,
      numberOfSeasons: data.seasonCount,
      isFilm: false,
      averageEpisodeRuntimeMinutes: 45,
    );
  }

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    return byShowId[tvId]?.episodesBySeason[seasonNumber] ?? const [];
  }
}

void main() {
  group('NewEpisodeChecker', () {
    late FakeEpisodeCheckStore store;

    setUp(() {
      store = FakeEpisodeCheckStore();
    });

    test('creates alert only for the immediate next aired episode', () async {
      const show = TvShow(id: 42, title: 'Sample Show');
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
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
      expect(result.newlyDetected.first.runtimeMinutes, 45);
      expect(result.allAlerts, hasLength(1));
    });

    test('skips aired next episode when runtime cannot be resolved', () async {
      const show = TvShow(id: 42, title: 'Sample Show');
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
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
        averageEpisodeRuntimeMinutes: null,
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
              'name': 'Airing Soon',
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

      expect(result.allAlerts, isEmpty);
      expect(result.newlyDetected, isEmpty);
    });

    test('skips later aired episodes when an earlier next episode exists', () async {
      const show = TvShow(id: 42, title: 'Sample Show');
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
          isFilm: false,
          episodeId: 200,
          seasonNumber: 2,
          episodeNumber: 3,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      final tmdb = StubTmdbService(
        seasonCount: 2,
        episodesBySeason: {
          2: [
            EpisodeModel.fromJson({
              'id': 200,
              'season_number': 2,
              'episode_number': 3,
              'name': 'Registered',
              'air_date': '2026-01-01',
            }),
            EpisodeModel.fromJson({
              'id': 201,
              'season_number': 2,
              'episode_number': 4,
              'name': 'Immediate Next',
              'air_date': '2026-01-08',
            }),
            EpisodeModel.fromJson({
              'id': 211,
              'season_number': 2,
              'episode_number': 14,
              'name': 'Latest Aired',
              'air_date': '2026-03-01',
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

      expect(result.allAlerts, hasLength(1));
      expect(result.allAlerts.first.seasonNumber, 2);
      expect(result.allAlerts.first.episodeNumber, 4);
      expect(result.allAlerts.first.episodeName, 'Immediate Next');
    });

    test('moves to the first episode of the next season when needed', () async {
      const show = TvShow(id: 42, title: 'Sample Show');
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
          isFilm: false,
          episodeId: 300,
          seasonNumber: 1,
          episodeNumber: 10,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      final tmdb = StubTmdbService(
        seasonCount: 2,
        episodesBySeason: {
          1: [
            EpisodeModel.fromJson({
              'id': 300,
              'season_number': 1,
              'episode_number': 10,
              'name': 'Finale',
              'air_date': '2026-01-01',
            }),
          ],
          2: [
            EpisodeModel.fromJson({
              'id': 301,
              'season_number': 2,
              'episode_number': 1,
              'name': 'Season Premiere',
              'air_date': '2026-02-01',
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

      expect(result.allAlerts, hasLength(1));
      expect(result.allAlerts.first.seasonNumber, 2);
      expect(result.allAlerts.first.episodeNumber, 1);
    });

    test(
      'skips undated in-season stubs and surfaces next season premiere',
      () async {
        const show = TvShow(id: 42, title: 'Sample Show');
        final watchHistory = [
          WatchRecord(
            mediaId: 42,
            isFilm: false,
            episodeId: 300,
            seasonNumber: 1,
            episodeNumber: 10,
            durationMinutes: 45,
            watchedAt: DateTime(2026, 1, 1),
          ),
        ];

        final tmdb = StubTmdbService(
          seasonCount: 2,
          episodesBySeason: {
            1: [
              EpisodeModel.fromJson({
                'id': 300,
                'season_number': 1,
                'episode_number': 10,
                'name': 'Finale',
                'air_date': '2026-01-01',
              }),
              EpisodeModel.fromJson({
                'id': 399,
                'season_number': 1,
                'episode_number': 11,
                'name': '',
                // Undated TMDB stub — must not block S2E1.
              }),
            ],
            2: [
              EpisodeModel.fromJson({
                'id': 301,
                'season_number': 2,
                'episode_number': 1,
                'name': 'Season Premiere',
                'air_date': '2026-02-01',
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

        expect(result.allAlerts, hasLength(1));
        expect(result.allAlerts.first.episodeId, 301);
        expect(result.allAlerts.first.seasonNumber, 2);
        expect(result.allAlerts.first.episodeNumber, 1);
      },
    );

    test(
      'keeps waiting when the next in-season episode is upcoming',
      () async {
        const show = TvShow(id: 42, title: 'Sample Show');
        final watchHistory = [
          WatchRecord(
            mediaId: 42,
            isFilm: false,
            episodeId: 300,
            seasonNumber: 1,
            episodeNumber: 10,
            durationMinutes: 45,
            watchedAt: DateTime(2026, 1, 1),
          ),
        ];

        final tmdb = StubTmdbService(
          seasonCount: 2,
          episodesBySeason: {
            1: [
              EpisodeModel.fromJson({
                'id': 300,
                'season_number': 1,
                'episode_number': 10,
                'name': 'Finale',
                'air_date': '2026-01-01',
              }),
              EpisodeModel.fromJson({
                'id': 311,
                'season_number': 1,
                'episode_number': 11,
                'name': 'Next Week',
                'air_date': '2099-06-01',
              }),
            ],
            2: [
              EpisodeModel.fromJson({
                'id': 301,
                'season_number': 2,
                'episode_number': 1,
                'name': 'Season Premiere',
                'air_date': '2020-02-01',
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

        expect(result.allAlerts, isEmpty);
      },
    );

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

    test('surfaces ended shows when next aired episode is available', () async {
      const show = TvShow(
        id: 42,
        title: 'Finished Show',
        status: 'Returning Series',
      );
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
          isFilm: false,
          episodeId: 100,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      final tmdb = StubTmdbService(
        seasonCount: 1,
        detailsStatus: 'Ended',
        episodesBySeason: {
          1: [
            EpisodeModel.fromJson({
              'id': 100,
              'season_number': 1,
              'episode_number': 1,
              'name': 'Pilot',
              'air_date': '2020-01-01',
            }),
            EpisodeModel.fromJson({
              'id': 101,
              'season_number': 1,
              'episode_number': 2,
              'name': 'Next',
              'air_date': '2020-01-08',
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

      expect(result.allAlerts, hasLength(1));
      expect(result.allAlerts.first.seasonNumber, 1);
      expect(result.allAlerts.first.episodeNumber, 2);
      expect(tmdb.seasonFetchCount, greaterThan(0));
    });

    test(
        'surfaces ended shows across seasons when next season premiere aired',
        () async {
      const show = TvShow(
        id: 42,
        title: 'Finished Show',
        status: 'Ended',
      );
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
          isFilm: false,
          episodeId: 110,
          seasonNumber: 1,
          episodeNumber: 10,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      final tmdb = StubTmdbService(
        seasonCount: 2,
        detailsStatus: 'Ended',
        episodesBySeason: {
          1: [
            EpisodeModel.fromJson({
              'id': 110,
              'season_number': 1,
              'episode_number': 10,
              'name': 'Finale',
              'air_date': '2020-01-01',
            }),
          ],
          2: [
            EpisodeModel.fromJson({
              'id': 201,
              'season_number': 2,
              'episode_number': 1,
              'name': 'Season Premiere',
              'air_date': '2020-02-01',
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

      expect(result.allAlerts, hasLength(1));
      expect(result.allAlerts.first.seasonNumber, 2);
      expect(result.allAlerts.first.episodeNumber, 1);
    });

    test('skips ended shows when last episode of last season is registered',
        () async {
      const show = TvShow(
        id: 42,
        title: 'Finished Show',
        status: 'Ended',
      );
      final watchHistory = [
        WatchRecord(
          mediaId: 42,
          isFilm: false,
          episodeId: 210,
          seasonNumber: 2,
          episodeNumber: 1,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      final tmdb = StubTmdbService(
        seasonCount: 2,
        detailsStatus: 'Ended',
        episodesBySeason: {
          2: [
            EpisodeModel.fromJson({
              'id': 210,
              'season_number': 2,
              'episode_number': 1,
              'name': 'Finale',
              'air_date': '2020-02-01',
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

      expect(result.newlyDetected, isEmpty);
      expect(result.allAlerts, isEmpty);
    });

    test('orders alerts by airDate then last catalogue activity', () async {
      const olderAir = TvShow(id: 1, title: 'Older Air');
      const newerAir = TvShow(id: 2, title: 'Newer Air');
      const sameAirRecentAdd = TvShow(id: 3, title: 'Same Air Recent');
      const sameAirOlderAdd = TvShow(id: 4, title: 'Same Air Older');

      final watchHistory = [
        WatchRecord(
          mediaId: 1,
          isFilm: false,
          episodeId: 10,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
        WatchRecord(
          mediaId: 2,
          isFilm: false,
          episodeId: 20,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
        WatchRecord(
          mediaId: 3,
          isFilm: false,
          episodeId: 30,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 3, 1),
        ),
        WatchRecord(
          mediaId: 4,
          isFilm: false,
          episodeId: 40,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 2, 1),
        ),
      ];

      EpisodeModel ep({
        required int id,
        required int season,
        required int number,
        required String airDate,
      }) {
        return EpisodeModel.fromJson({
          'id': id,
          'season_number': season,
          'episode_number': number,
          'name': 'E$number',
          'air_date': airDate,
          'runtime': 45,
        });
      }

      final tmdb = MultiShowStubTmdbService(
        byShowId: {
          1: (
            seasonCount: 1,
            episodesBySeason: {
              1: [
                ep(id: 10, season: 1, number: 1, airDate: '2026-01-01'),
                ep(id: 11, season: 1, number: 2, airDate: '2026-01-10'),
              ],
            },
          ),
          2: (
            seasonCount: 1,
            episodesBySeason: {
              1: [
                ep(id: 20, season: 1, number: 1, airDate: '2026-01-01'),
                ep(id: 21, season: 1, number: 2, airDate: '2026-02-10'),
              ],
            },
          ),
          3: (
            seasonCount: 1,
            episodesBySeason: {
              1: [
                ep(id: 30, season: 1, number: 1, airDate: '2026-01-01'),
                ep(id: 31, season: 1, number: 2, airDate: '2026-01-20'),
              ],
            },
          ),
          4: (
            seasonCount: 1,
            episodesBySeason: {
              1: [
                ep(id: 40, season: 1, number: 1, airDate: '2026-01-01'),
                ep(id: 41, season: 1, number: 2, airDate: '2026-01-20'),
              ],
            },
          ),
        },
      );

      final checker = NewEpisodeChecker(
        tmdbService: tmdb,
        userDataStore: store,
      );

      final result = await checker.checkShows(
        shows: [olderAir, newerAir, sameAirRecentAdd, sameAirOlderAdd],
        watchHistory: watchHistory,
      );

      expect(result.allAlerts.map((a) => a.showId).toList(), [2, 3, 4, 1]);
    });

    test(
      'uses details poster when catalogue show has no posterPath',
      () async {
        const show = TvShow(id: 42, title: 'Sample Show');
        final watchHistory = [
          WatchRecord(
            mediaId: 42,
            isFilm: false,
            episodeId: 100,
            seasonNumber: 1,
            episodeNumber: 1,
            durationMinutes: 45,
            watchedAt: DateTime(2026, 1, 1),
          ),
        ];

        final tmdb = StubTmdbService(
          seasonCount: 1,
          detailsPosterPath: '/from-details.jpg',
          episodesBySeason: {
            1: [
              EpisodeModel.fromJson({
                'id': 100,
                'season_number': 1,
                'episode_number': 1,
                'name': 'Pilot',
                'air_date': '2026-01-01',
                'runtime': 45,
              }),
              EpisodeModel.fromJson({
                'id': 101,
                'season_number': 1,
                'episode_number': 2,
                'name': 'Next',
                'air_date': '2026-01-08',
                'runtime': 45,
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

        expect(result.allAlerts, hasLength(1));
        expect(result.allAlerts.single.showPosterPath, '/from-details.jpg');
      },
    );

    test(
      'preserves prior alert poster when catalogue and details lack one',
      () async {
        const show = TvShow(id: 42, title: 'Sample Show');
        final watchHistory = [
          WatchRecord(
            mediaId: 42,
            isFilm: false,
            episodeId: 100,
            seasonNumber: 1,
            episodeNumber: 1,
            durationMinutes: 45,
            watchedAt: DateTime(2026, 1, 1),
          ),
        ];

        final prior = NewEpisodeAlert(
          showId: 42,
          showTitle: 'Sample Show',
          showPosterPath: '/prior-poster.jpg',
          episodeId: 99,
          seasonNumber: 1,
          episodeNumber: 1,
          episodeName: 'Old',
          airDate: DateTime(2026, 1, 1),
          detectedAt: DateTime(2026, 1, 2),
        );

        final tmdb = StubTmdbService(
          seasonCount: 1,
          episodesBySeason: {
            1: [
              EpisodeModel.fromJson({
                'id': 100,
                'season_number': 1,
                'episode_number': 1,
                'name': 'Pilot',
                'air_date': '2026-01-01',
                'runtime': 45,
              }),
              EpisodeModel.fromJson({
                'id': 101,
                'season_number': 1,
                'episode_number': 2,
                'name': 'Next',
                'air_date': '2026-01-08',
                'runtime': 45,
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
          existingAlerts: [prior],
        );

        expect(result.allAlerts, hasLength(1));
        expect(result.allAlerts.single.showPosterPath, '/prior-poster.jpg');
        expect(result.allAlerts.single.episodeId, 101);
      },
    );
  });
}
