import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/show_in_progress.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';

void main() {
  group('isAvailableImmediateNextEpisode', () {
    test('true when aired and not registered', () {
      final episode = EpisodeModel.fromJson({
        'id': 101,
        'season_number': 1,
        'episode_number': 3,
        'name': 'Next',
        'air_date': '2020-01-01',
      });

      expect(isAvailableImmediateNextEpisode(episode, const []), isTrue);
    });

    test('false when already registered', () {
      final episode = EpisodeModel.fromJson({
        'id': 101,
        'season_number': 1,
        'episode_number': 3,
        'name': 'Next',
        'air_date': '2020-01-01',
      });
      final history = [
        WatchRecord(
          mediaId: 42,
          isFilm: false,
          episodeId: 101,
          seasonNumber: 1,
          episodeNumber: 3,
          durationMinutes: 40,
          watchedAt: DateTime(2026, 1, 1),
        ),
      ];

      expect(isAvailableImmediateNextEpisode(episode, history), isFalse);
    });
  });

  group('isSeriesInProgress / isShowInProgress', () {
    test('true for ongoing TMDB statuses', () {
      expect(
        isSeriesInProgress(status: 'Returning Series'),
        isTrue,
      );
      expect(isSeriesInProgress(status: 'Planned'), isTrue);
      expect(isSeriesInProgress(status: 'In Production'), isTrue);
      expect(isSeriesInProgress(status: 'Pilot'), isTrue);
    });

    test('false for concluded statuses without a next episode', () {
      expect(isSeriesInProgress(status: 'Ended'), isFalse);
      expect(isSeriesInProgress(status: 'Canceled'), isFalse);
      expect(isSeriesInProgress(status: 'Cancelled'), isFalse);
      expect(isSeriesInProgress(), isFalse);
    });

    test('true when a next episode is scheduled even if ended', () {
      expect(
        isSeriesInProgress(
          status: 'Ended',
          nextEpisodeAirDate: '2026-10-01',
        ),
        isTrue,
      );
    });

    test('reads fields from TvShow', () {
      const ongoing = TvShow(
        id: 1,
        title: 'Ongoing',
        status: 'Returning Series',
      );
      const ended = TvShow(
        id: 2,
        title: 'Ended',
        status: 'Ended',
      );
      const upcoming = TvShow(
        id: 3,
        title: 'Upcoming',
        status: 'Ended',
        nextEpisodeAirDate: '2026-12-01',
      );

      expect(isShowInProgress(ongoing), isTrue);
      expect(isShowInProgress(ended), isFalse);
      expect(isShowInProgress(upcoming), isTrue);
    });
  });
}
