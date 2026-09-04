import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/show_in_progress.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
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
          mediaTitle: 'Show',
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

  group('isShowInProgress / inProgressShowIds', () {
    final alerts = [
      NewEpisodeAlert(
        showId: 10,
        showTitle: 'A',
        episodeId: 1,
        seasonNumber: 1,
        episodeNumber: 2,
        episodeName: 'E2',
        detectedAt: DateTime(2026, 1, 1),
      ),
      NewEpisodeAlert(
        showId: 20,
        showTitle: 'B',
        episodeId: 2,
        seasonNumber: 2,
        episodeNumber: 1,
        episodeName: 'E1',
        detectedAt: DateTime(2026, 1, 1),
      ),
    ];

    test('matches alert show ids', () {
      expect(isShowInProgress(10, alerts: alerts), isTrue);
      expect(isShowInProgress(99, alerts: alerts), isFalse);
      expect(inProgressShowIds(alerts: alerts), {10, 20});
    });
  });
}
