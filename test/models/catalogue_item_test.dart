import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';

void main() {
  group('Film.fromJson', () {
    test('parses TMDB movie payload', () {
      final film = Film.fromJson({
        'id': 550,
        'title': 'Fight Club',
        'overview': 'An insomniac office worker...',
        'poster_path': '/poster.jpg',
        'vote_average': 8.4,
      });

      expect(film.id, 550);
      expect(film.title, 'Fight Club');
      expect(film.overview, isNotNull);
      expect(film.posterPath, '/poster.jpg');
      expect(film.voteAverage, 8.4);
    });
  });

  group('TvShow.fromJson', () {
    test('parses TMDB TV payload', () {
      final show = TvShow.fromJson({
        'id': 1399,
        'name': 'Game of Thrones',
        'overview': 'Nine noble families...',
        'poster_path': '/got.jpg',
        'vote_average': 8.5,
      });

      expect(show.id, 1399);
      expect(show.title, 'Game of Thrones');
      expect(show.seasonNumber, 1);
      expect(show.episodeNumber, 1);
    });
  });

  group('catalogueItemFromSearchJson', () {
    test('returns Film for movie media type', () {
      final item = catalogueItemFromSearchJson({
        'media_type': 'movie',
        'id': 1,
        'title': 'Test Movie',
        'vote_average': 7.0,
      });

      expect(item, isA<Film>());
    });

    test('returns TvShow for tv media type', () {
      final item = catalogueItemFromSearchJson({
        'media_type': 'tv',
        'id': 2,
        'name': 'Test Show',
        'vote_average': 8.0,
      });

      expect(item, isA<TvShow>());
    });

    test('returns null for unsupported media type', () {
      final item = catalogueItemFromSearchJson({
        'media_type': 'person',
        'id': 3,
        'name': 'Actor',
      });

      expect(item, isNull);
    });
  });

  group('EpisodeModel.fromJson', () {
    test('parses episode with air date', () {
      final episode = EpisodeModel.fromJson({
        'id': 10,
        'episode_number': 1,
        'season_number': 1,
        'name': 'Pilot',
        'air_date': '2024-06-01',
        'still_path': '/still.jpg',
        'runtime': 58,
      });

      expect(episode.episodeNumber, 1);
      expect(episode.seasonNumber, 1);
      expect(episode.airDate, DateTime(2024, 6, 1));
      expect(episode.runtimeMinutes, 58);
    });
  });
}
