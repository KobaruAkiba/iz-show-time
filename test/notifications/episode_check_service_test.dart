import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:iz_show_time_tracker/core/background/background_task_kind.dart';
import 'package:iz_show_time_tracker/core/network/api_error.dart';
import 'package:iz_show_time_tracker/core/notifications/episode_check_service.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/tv_show_summary.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/repositories/background_check_outbox.dart';
import 'package:iz_show_time_tracker/data/repositories/hive_user_data_store.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

final String _yesterday = DateTime.now()
    .subtract(const Duration(days: 1))
    .toIso8601String()
    .substring(0, 10);

/// Every show has two aired episodes unless [episodeCount] says otherwise;
/// ids are `showId * 10 + episodeNumber`.
/// Shows in [interruptedShowIds] throw a non-API error, like a killed run.
/// Shows in [apiFailingShowIds] throw a transient TMDB error.
class _TwoEpisodeStubTmdbService extends TmdbService {
  _TwoEpisodeStubTmdbService({
    this.interruptedShowIds = const {},
    this.apiFailingShowIds = const {},
    this.episodeCount = const {},
  }) : super(cacheManager: null);

  final Set<int> interruptedShowIds;
  final Set<int> apiFailingShowIds;

  /// Episodes per show id, when not two.
  final Map<int, int> episodeCount;

  @override
  Future<TvShowSummary?> getTvShowSummary(
    int tvId, {
    bool forceRefresh = false,
  }) async {
    return const TvShowSummary(numberOfSeasons: 1);
  }

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    if (interruptedShowIds.contains(tvId)) {
      throw StateError('run interrupted');
    }
    if (apiFailingShowIds.contains(tvId)) {
      throw const ApiException(ApiErrorType.timeout, 'timeout');
    }
    return [
      for (var number = 1; number <= (episodeCount[tvId] ?? 2); number++)
        EpisodeModel.fromJson({
          'id': tvId * 10 + number,
          'season_number': 1,
          'episode_number': number,
          'name': 'E$number',
          // Recent, so the alert is eligible for a system notification.
          'air_date': _yesterday,
          'runtime': 40,
        }),
    ];
  }
}

void main() {
  group('rotateShowsAfter', () {
    const shows = [
      TvShow(id: 3, title: 'C'),
      TvShow(id: 1, title: 'A'),
      TvShow(id: 2, title: 'B'),
    ];
    List<int> ids(int? resumeAfter) =>
        rotateShowsAfter(shows, resumeAfter).map((show) => show.id).toList();

    test('sorts by id without a cursor', () {
      expect(ids(null), [1, 2, 3]);
    });

    test('starts after the cursor and wraps around', () {
      expect(ids(1), [2, 3, 1]);
      expect(ids(2), [3, 1, 2]);
    });

    test('restarts from the first show after a full cycle', () {
      expect(ids(3), [1, 2, 3]);
      expect(ids(99), [1, 2, 3]);
    });
  });

  group('EpisodeCheckService.checkAndStore', () {
    late Directory tempDir;
    late BackgroundCheckOutbox outbox;

    // Five followed shows, each with episode 1 registered.
    final snapshot = UserDataSnapshot(
      catalogue: [
        for (var id = 1; id <= 5; id++)
          TvShow(id: id, title: 'Show $id', tags: const [kFollowedTag]),
      ],
      watchHistory: [
        for (var id = 1; id <= 5; id++)
          WatchRecord(
            mediaId: id,
            isFilm: false,
            episodeId: id * 10 + 1,
            seasonNumber: 1,
            episodeNumber: 1,
            durationMinutes: 40,
            watchedAt: DateTime(2026, 1, 1),
          ),
      ],
      newEpisodeAlerts: const [],
      appInForeground: false,
      notifiedEpisodeIds: const {},
    );

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('episode_check_service_');
      Hive.init(tempDir.path);
      outbox = await BackgroundCheckOutbox.openForWriting();
    });

    tearDown(() async {
      await outbox.close();
      await Hive.deleteFromDisk();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Set<int> storedEpisodeIds() =>
        {for (final alert in outbox.result!.alerts) alert.episodeId};

    test('an interrupted run keeps its completed blocks and is resumed',
        () async {
      final notifications = <({int count, bool silent})>[];
      Future<bool> notify(int count, {required bool silent}) async {
        notifications.add((count: count, silent: silent));
        return true;
      }

      // Blocks of two: [1, 2] completes, [3, 4] is interrupted.
      await expectLater(
        EpisodeCheckService.checkAndStore(
          snapshot: snapshot,
          tmdbService: _TwoEpisodeStubTmdbService(interruptedShowIds: {3}),
          outbox: outbox,
          notify: notify,
          blockSize: 2,
        ),
        throwsStateError,
      );

      expect(storedEpisodeIds(), {12, 22});
      expect(outbox.resumeAfterShowId, 2);
      expect(outbox.notifiedEpisodeIds, {12, 22});
      expect(notifications, [(count: 2, silent: false)]);

      // Next run starts at show 3 and keeps the alerts already found.
      notifications.clear();
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: notify,
        blockSize: 2,
      );

      expect(storedEpisodeIds(), {12, 22, 32, 42, 52});
      expect(outbox.notifiedEpisodeIds, {12, 22, 32, 42, 52});
      // The app was not opened in between: the notification keeps counting
      // shows 1 and 2, then adds 3, 4 and 5.
      expect(notifications, [
        (count: 4, silent: false),
        (count: 5, silent: true),
      ]);
      expect(outbox.resumeAfterShowId, 2);
    });

    test('stores the kind of task that ran the check', () async {
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (_, {required silent}) async => true,
        taskKind: BackgroundTaskKind.nightly,
      );

      expect(outbox.result!.taskKind, BackgroundTaskKind.nightly);
    });

    test('counts every aired episode of a show, not one per show', () async {
      final notifications = <({int count, bool silent})>[];

      // Show 1: episodes 2, 3 and 4 aired after the registered episode 1.
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(episodeCount: {1: 4}),
        outbox: outbox,
        notify: (count, {required silent}) async {
          notifications.add((count: count, silent: silent));
          return true;
        },
      );

      // Show 1 counts 3 episodes, shows 2 to 5 one each.
      expect(notifications, [(count: 7, silent: false)]);
      expect(outbox.notifiedEpisodeIds, containsAll([12, 13, 14]));
      final alert =
          outbox.result!.alerts.firstWhere((alert) => alert.showId == 1);
      expect(alert.episodeId, 12);
      expect(
        alert.laterAiredEpisodes.map((episode) => episode.episodeId),
        [13, 14],
      );
    });

    test('restarts the count after the app was opened', () async {
      final notifications = <({int count, bool silent})>[];
      Future<bool> notify(int count, {required bool silent}) async {
        notifications.add((count: count, silent: silent));
        return true;
      }

      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: notify,
      );
      expect(notifications, [(count: 5, silent: false)]);

      // The user opened and left the app; then show 1 gets a third episode.
      notifications.clear();
      await EpisodeCheckService.checkAndStore(
        snapshot: UserDataSnapshot(
          catalogue: snapshot.catalogue,
          watchHistory: snapshot.watchHistory,
          newEpisodeAlerts: const [],
          appInForeground: false,
          notifiedEpisodeIds: const {},
          appLeftForegroundAt: DateTime.now(),
        ),
        tmdbService: _TwoEpisodeStubTmdbService(episodeCount: {1: 3}),
        outbox: outbox,
        notify: notify,
      );

      expect(notifications, [(count: 1, silent: false)]);
      expect(outbox.notifiedAt.keys, [13]);
    });

    test('does not notify while the app is in foreground', () async {
      final notifications = <({int count, bool silent})>[];

      await EpisodeCheckService.checkAndStore(
        snapshot: UserDataSnapshot(
          catalogue: snapshot.catalogue,
          watchHistory: snapshot.watchHistory,
          newEpisodeAlerts: const [],
          appInForeground: true,
          notifiedEpisodeIds: const {},
          appForegroundHeartbeatAt: DateTime.now(),
        ),
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (count, {required silent}) async {
          notifications.add((count: count, silent: silent));
          return true;
        },
      );

      expect(storedEpisodeIds(), hasLength(5));
      expect(notifications, isEmpty);
      expect(outbox.notifiedEpisodeIds, isEmpty);
    });

    test('notifies when the foreground flag is stale', () async {
      final notifications = <({int count, bool silent})>[];

      // Left true by a crash: the heartbeat stopped an hour ago.
      await EpisodeCheckService.checkAndStore(
        snapshot: UserDataSnapshot(
          catalogue: snapshot.catalogue,
          watchHistory: snapshot.watchHistory,
          newEpisodeAlerts: const [],
          appInForeground: true,
          notifiedEpisodeIds: const {},
          appForegroundHeartbeatAt:
              DateTime.now().subtract(const Duration(hours: 1)),
        ),
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (count, {required silent}) async {
          notifications.add((count: count, silent: silent));
          return true;
        },
      );

      expect(notifications, [(count: 5, silent: false)]);
    });

    test('a transient TMDB failure does not notify the same episode again',
        () async {
      final notifications = <({int count, bool silent})>[];
      Future<bool> notify(int count, {required bool silent}) async {
        notifications.add((count: count, silent: silent));
        return true;
      }

      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: notify,
      );
      expect(outbox.notifiedEpisodeIds, {12, 22, 32, 42, 52});

      // TMDB fails for show 1 while show 2 gets a new episode in the same run.
      notifications.clear();
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(
          apiFailingShowIds: {1},
          episodeCount: {2: 3},
        ),
        outbox: outbox,
        notify: notify,
      );

      expect(notifications, [(count: 6, silent: false)]);
      expect(outbox.notifiedEpisodeIds, contains(12));
      expect(storedEpisodeIds(), contains(12));

      // TMDB answers again: episode 12 was already notified.
      notifications.clear();
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(episodeCount: {2: 3}),
        outbox: outbox,
        notify: notify,
      );

      expect(notifications, isEmpty);
    });

    test('alerts once per run and updates silently afterwards', () async {
      final notifications = <({int count, bool silent})>[];

      // Blocks of two: [1, 2], [3, 4], [5] each notify an updated total.
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (count, {required silent}) async {
          notifications.add((count: count, silent: silent));
          return true;
        },
        blockSize: 2,
      );

      expect(notifications, [
        (count: 2, silent: false),
        (count: 4, silent: true),
        (count: 5, silent: true),
      ]);
    });

    test('does not mark episodes while notifications are off', () async {
      final notifications = <({int count, bool silent})>[];

      // The notification is not shown (e.g. notifications disabled).
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (count, {required silent}) async {
          notifications.add((count: count, silent: silent));
          return false;
        },
      );

      expect(notifications, [(count: 5, silent: false)]);
      expect(outbox.notifiedEpisodeIds, isEmpty);
      expect(outbox.notifiedAt, isEmpty);

      // Notifications are enabled again: the same episodes are notified.
      notifications.clear();
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (count, {required silent}) async {
          notifications.add((count: count, silent: silent));
          return true;
        },
      );

      expect(notifications, [(count: 5, silent: false)]);
      expect(outbox.notifiedEpisodeIds, {12, 22, 32, 42, 52});
    });

    test('alerts with sound after a notification that was not shown', () async {
      final notifications = <({int count, bool silent})>[];

      // Blocks of two: the first notification fails, the next ones succeed.
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (count, {required silent}) async {
          notifications.add((count: count, silent: silent));
          return notifications.length > 1;
        },
        blockSize: 2,
      );

      expect(notifications, [
        (count: 2, silent: false),
        (count: 4, silent: false),
        (count: 5, silent: true),
      ]);
    });
  });
}
