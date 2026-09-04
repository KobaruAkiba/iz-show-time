import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/season_model.dart';

void main() {
  group('SeasonModel', () {
    test('parses season payload with air date and episodes', () {
      final season = SeasonModel.fromTmdbSeasonJson({
        'season_number': 2,
        'air_date': '2099-03-01',
        'episodes': [
          {
            'id': 1,
            'episode_number': 1,
            'season_number': 2,
            'name': 'Pilot',
            'air_date': '2099-03-01',
          },
        ],
      });

      expect(season.seasonNumber, 2);
      expect(season.airDate, DateTime(2099, 3, 1));
      expect(season.episodes, hasLength(1));
      expect(season.label, 'Season 2');
      expect(season.isUpcoming, isTrue);
    });

    test('marks empty seasons as upcoming', () {
      const season = SeasonModel(seasonNumber: 3, episodes: []);
      expect(season.isUpcoming, isTrue);
    });

    test('marks seasons with only future episodes as upcoming', () {
      final season = SeasonModel(
        seasonNumber: 2,
        airDate: DateTime(2099, 1, 1),
        episodes: [
          EpisodeModel(
            id: 1,
            seasonNumber: 2,
            episodeNumber: 1,
            name: 'One',
            airDate: DateTime(2099, 1, 1),
          ),
          EpisodeModel(
            id: 2,
            seasonNumber: 2,
            episodeNumber: 2,
            name: 'Two',
            airDate: DateTime(2099, 1, 8),
          ),
        ],
      );

      expect(season.isUpcoming, isTrue);
    });

    test('does not mark seasons with an aired episode as upcoming', () {
      final season = SeasonModel(
        seasonNumber: 1,
        airDate: DateTime(2020, 1, 1),
        episodes: [
          EpisodeModel(
            id: 1,
            seasonNumber: 1,
            episodeNumber: 1,
            name: 'Aired',
            airDate: DateTime(2020, 1, 1),
          ),
          EpisodeModel(
            id: 2,
            seasonNumber: 1,
            episodeNumber: 2,
            name: 'Future',
            airDate: DateTime(2099, 1, 1),
          ),
        ],
      );

      expect(season.isUpcoming, isFalse);
      expect(season.episodes.first.isUpcoming, isFalse);
      expect(season.episodes.last.isUpcoming, isTrue);
    });

    test('marks seasons of unnamed stub episodes as upcoming', () {
      const season = SeasonModel(
        seasonNumber: 2,
        episodes: [
          EpisodeModel(
            id: 1,
            seasonNumber: 2,
            episodeNumber: 1,
            name: '',
          ),
          EpisodeModel(
            id: 2,
            seasonNumber: 2,
            episodeNumber: 2,
            name: '  ',
          ),
        ],
      );

      expect(season.isUpcoming, isTrue);
      expect(season.episodes.every((e) => !e.isUpcoming), isTrue);
    });

    test('does not mark named episodes without dates as upcoming season', () {
      const season = SeasonModel(
        seasonNumber: 2,
        episodes: [
          EpisodeModel(
            id: 1,
            seasonNumber: 2,
            episodeNumber: 1,
            name: 'Named but undated',
          ),
        ],
      );

      expect(season.isUpcoming, isFalse);
      expect(season.episodes.single.isUpcoming, isFalse);
    });
  });
}
