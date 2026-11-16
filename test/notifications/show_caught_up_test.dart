import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/show_caught_up.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';

WatchRecord _episode(int showId, int season, int episode, {int? id}) {
  return WatchRecord(
    mediaId: showId,
    isFilm: false,
    episodeId: id ?? showId * 1000 + season * 100 + episode,
    seasonNumber: season,
    episodeNumber: episode,
    durationMinutes: 40,
    watchedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('lastRegisteredEpisodesByShowId', () {
    test('keeps the latest S/E per show, ignoring films and gaps', () {
      final history = [
        _episode(1, 1, 5),
        _episode(1, 2, 1),
        _episode(1, 1, 9),
        _episode(2, 3, 4),
        WatchRecord(
          mediaId: 3,
          isFilm: true,
          durationMinutes: 120,
          watchedAt: DateTime(2026, 1, 1),
        ),
        WatchRecord(
          mediaId: 4,
          isFilm: false,
          episodeId: 99,
          durationMinutes: 40,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      final result = lastRegisteredEpisodesByShowId(history);

      expect(result[1], (seasonNumber: 2, episodeNumber: 1));
      expect(result[2], (seasonNumber: 3, episodeNumber: 4));
      expect(result.containsKey(3), isFalse);
      expect(result.containsKey(4), isFalse);
    });
  });

  group('isShowCaughtUp', () {
    const show = TvShow(
      id: 1,
      title: 'Show',
      lastAiredSeasonNumber: 2,
      lastAiredEpisodeNumber: 5,
    );

    test('true when last registered equals last aired', () {
      expect(
        isShowCaughtUp(show, (seasonNumber: 2, episodeNumber: 5)),
        isTrue,
      );
    });

    test('true when last registered is later than last aired', () {
      expect(
        isShowCaughtUp(show, (seasonNumber: 3, episodeNumber: 1)),
        isTrue,
      );
    });

    test('false when a later episode has aired', () {
      expect(
        isShowCaughtUp(show, (seasonNumber: 2, episodeNumber: 4)),
        isFalse,
      );
      expect(
        isShowCaughtUp(show, (seasonNumber: 1, episodeNumber: 10)),
        isFalse,
      );
    });

    test('false without registered episodes', () {
      expect(isShowCaughtUp(show, null), isFalse);
    });

    test('false without last aired metadata', () {
      const unsynced = TvShow(id: 1, title: 'Show');
      expect(
        isShowCaughtUp(unsynced, (seasonNumber: 9, episodeNumber: 9)),
        isFalse,
      );
    });
  });
}
