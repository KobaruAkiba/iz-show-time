import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/utils/catalogue_activity.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_filters.dart';

void main() {
  group('lastCatalogueActivityByMediaId', () {
    test('keeps max watchedAt per mediaId', () {
      final map = lastCatalogueActivityByMediaId([
        WatchRecord(
          mediaId: 1,
          isFilm: false,
          episodeId: 10,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 40,
          watchedAt: DateTime(2026, 1, 1),
        ),
        WatchRecord(
          mediaId: 1,
          isFilm: false,
          episodeId: 11,
          seasonNumber: 1,
          episodeNumber: 2,
          durationMinutes: 40,
          watchedAt: DateTime(2026, 2, 1),
        ),
        WatchRecord(
          mediaId: 2,
          isFilm: true,
          durationMinutes: 120,
          watchedAt: DateTime(2026, 1, 15),
        ),
      ]);

      expect(map[1], DateTime(2026, 2, 1));
      expect(map[2], DateTime(2026, 1, 15));
    });
  });

  group('compareContinueWatchingAlerts', () {
    NewEpisodeAlert alert({
      required int showId,
      DateTime? airDate,
      int season = 1,
      int episode = 1,
    }) {
      return NewEpisodeAlert(
        showId: showId,
        showTitle: 'Show $showId',
        episodeId: showId * 100 + episode,
        seasonNumber: season,
        episodeNumber: episode,
        episodeName: 'E$episode',
        airDate: airDate,
        runtimeMinutes: 45,
        detectedAt: DateTime(2026, 3, 1),
      );
    }

    test('orders by airDate descending', () {
      final a = alert(showId: 1, airDate: DateTime(2026, 1, 1));
      final b = alert(showId: 2, airDate: DateTime(2026, 2, 1));
      final activity = <int, DateTime>{};

      expect(compareContinueWatchingAlerts(b, a, activity), lessThan(0));
      expect(compareContinueWatchingAlerts(a, b, activity), greaterThan(0));
    });

    test('null airDate sorts after dated alerts', () {
      final dated = alert(showId: 1, airDate: DateTime(2026, 1, 1));
      final undated = alert(showId: 2, airDate: null);
      final activity = <int, DateTime>{};

      expect(
        compareContinueWatchingAlerts(dated, undated, activity),
        lessThan(0),
      );
    });

    test('tie-breaks on last catalogue activity then showId', () {
      final a = alert(showId: 1, airDate: DateTime(2026, 1, 1));
      final b = alert(showId: 2, airDate: DateTime(2026, 1, 1));
      final activity = {
        1: DateTime(2026, 1, 10),
        2: DateTime(2026, 1, 20),
      };

      expect(compareContinueWatchingAlerts(b, a, activity), lessThan(0));

      final sameActivity = {
        1: DateTime(2026, 1, 10),
        2: DateTime(2026, 1, 10),
      };
      expect(
        compareContinueWatchingAlerts(a, b, sameActivity),
        lessThan(0),
      );
    });
  });

  group('compareCatalogueByLastActivity / applyMediaFilters', () {
    test('default sort puts recent activity first; nulls last; title tie-break',
        () {
      const filmRecent = Film(id: 1, title: 'Zebra Film');
      const filmOld = Film(id: 2, title: 'Alpha Film');
      const showRecent = TvShow(id: 3, title: 'Beta Show');
      const orphan = Film(id: 4, title: 'Orphan Film');

      final activity = {
        1: DateTime(2026, 3, 1),
        2: DateTime(2026, 1, 1),
        3: DateTime(2026, 2, 1),
      };

      final sorted = applyMediaFilters(
        [orphan, filmOld, showRecent, filmRecent],
        mediaFilter: MediaFilter.all,
        sortOption: MediaSortOption.none,
        lastCatalogueActivityByMediaId: activity,
      );

      expect(sorted.map((item) => item.id).toList(), [1, 3, 2, 4]);
    });

    test('items with same activity sort by title then id', () {
      const a = Film(id: 10, title: 'Beta');
      const b = Film(id: 11, title: 'Alpha');
      final sameDay = DateTime(2026, 1, 1);

      final sorted = applyMediaFilters(
        [a, b],
        mediaFilter: MediaFilter.all,
        sortOption: MediaSortOption.none,
        lastCatalogueActivityByMediaId: {10: sameDay, 11: sameDay},
      );

      expect(sorted.map((item) => item.id).toList(), [11, 10]);
    });
  });
}
