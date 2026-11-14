import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:iz_show_time_tracker/core/notifications/episode_check_service.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/tv_show_summary.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/repositories/background_check_outbox.dart';
import 'package:iz_show_time_tracker/data/repositories/hive_user_data_store.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

/// Every show has two aired episodes; ids are `showId * 10 + episodeNumber`.
/// Shows in [interruptedShowIds] throw a non-API error, like a killed run.
class _TwoEpisodeStubTmdbService extends TmdbService {
  _TwoEpisodeStubTmdbService({this.interruptedShowIds = const {}})
      : super(cacheManager: null);

  final Set<int> interruptedShowIds;

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
      for (var number = 1; number <= 2; number++)
        EpisodeModel.fromJson({
          'id': tvId * 10 + number,
          'season_number': 1,
          'episode_number': number,
          'name': 'E$number',
          'air_date': '2020-01-0$number',
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
      // Shows 1 and 2 were already notified: only 3, 4 and then 5 count.
      expect(notifications, [2, 3]);
      expect(outbox.resumeAfterShowId, 2);
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
