import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:iz_show_time_tracker/core/background/background_task_kind.dart';
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
class _TwoEpisodeStubTmdbService extends TmdbService {
  _TwoEpisodeStubTmdbService({
    this.interruptedShowIds = const {},
    this.episodeCount = const {},
  }) : super(cacheManager: null);

  final Set<int> interruptedShowIds;

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
      final notifications = <int>[];
      Future<void> notify(int count) async => notifications.add(count);

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
      expect(notifications, [2]);

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
      expect(notifications, [4, 5]);
      expect(outbox.resumeAfterShowId, 2);
    });

    test('stores the kind of task that ran the check', () async {
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (_) async {},
        taskKind: BackgroundTaskKind.nightly,
      );

      expect(outbox.result!.taskKind, BackgroundTaskKind.nightly);
    });

    test('counts every aired episode of a show, not one per show', () async {
      final notifications = <int>[];

      // Show 1: episodes 2, 3 and 4 aired after the registered episode 1.
      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(episodeCount: {1: 4}),
        outbox: outbox,
        notify: (count) async => notifications.add(count),
      );

      // Show 1 counts 3 episodes, shows 2 to 5 one each.
      expect(notifications, [7]);
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
      final notifications = <int>[];
      Future<void> notify(int count) async => notifications.add(count);

      await EpisodeCheckService.checkAndStore(
        snapshot: snapshot,
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: notify,
      );
      expect(notifications, [5]);

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

      expect(notifications, [1]);
      expect(outbox.notifiedAt.keys, [13]);
    });

    test('does not notify while the app is in foreground', () async {
      final notifications = <int>[];

      await EpisodeCheckService.checkAndStore(
        snapshot: UserDataSnapshot(
          catalogue: snapshot.catalogue,
          watchHistory: snapshot.watchHistory,
          newEpisodeAlerts: const [],
          appInForeground: true,
          notifiedEpisodeIds: const {},
        ),
        tmdbService: _TwoEpisodeStubTmdbService(),
        outbox: outbox,
        notify: (count) async => notifications.add(count),
      );

      expect(storedEpisodeIds(), hasLength(5));
      expect(notifications, isEmpty);
      expect(outbox.notifiedEpisodeIds, isEmpty);
    });
  });
}
