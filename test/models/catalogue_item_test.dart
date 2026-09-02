import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/season_model.dart';
import 'package:iz_show_time_tracker/core/notifications/episode_signature.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';

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

  group('EpisodeModel', () {
    test('parses episode payload', () {
      final episode = EpisodeModel.fromJson({
        'id': 10,
        'episode_number': 14,
        'season_number': 2,
        'name': 'The Rains of Castamere',
        'runtime': 58,
        'air_date': '2013-06-02',
      });

      expect(episode.episodeNumber, 14);
      expect(episode.seasonNumber, 2);
      expect(episode.runtimeMinutes, 58);
      expect(episode.airDate, DateTime(2013, 6, 2));
      expect(episode.codeLabel, 'S2 E14');
      expect(episode.displayTitle, 'The Rains of Castamere');
      expect(episode.hasAired, isTrue);
    });

    test('treats future air dates as not aired', () {
      final episode = EpisodeModel.fromJson({
        'id': 11,
        'episode_number': 1,
        'season_number': 9,
        'name': 'Finale',
        'air_date': '2099-01-01',
      });

      expect(episode.hasAired, isFalse);
    });
  });

  group('Episode signature helpers', () {
    test('finds latest registered S/E from watch history', () {
      final history = [
        WatchRecord(
          mediaId: 10,
          mediaTitle: 'Show',
          isFilm: false,
          episodeId: 1,
          seasonNumber: 1,
          episodeNumber: 3,
          durationMinutes: 45,
          watchedAt: DateTime(2026, 1, 1),
        ),
        WatchRecord(
          mediaId: 10,
          mediaTitle: 'Show',
          isFilm: false,
          episodeId: 2,
          seasonNumber: 2,
          episodeNumber: 1,
          durationMinutes: 50,
          watchedAt: DateTime(2026, 2, 1),
        ),
      ];

      final latest = lastRegisteredEpisodeForShow(10, history);

      expect(latest?.seasonNumber, 2);
      expect(latest?.episodeNumber, 1);
    });

    test('detects aired episodes after last registered signature', () {
      const lastRegistered = (seasonNumber: 2, episodeNumber: 5);
      const newer = EpisodeModel(
        id: 1,
        seasonNumber: 2,
        episodeNumber: 6,
        name: 'Next',
      );
      const same = EpisodeModel(
        id: 2,
        seasonNumber: 2,
        episodeNumber: 5,
        name: 'Same',
      );

      expect(isEpisodeAfterSignature(newer, lastRegistered), isTrue);
      expect(isEpisodeAfterSignature(same, lastRegistered), isFalse);
    });
  });

  group('SeasonModel', () {
    test('groups episodes under a season label', () {
      const season = SeasonModel(
        seasonNumber: 1,
        episodes: [
          EpisodeModel(
            id: 1,
            seasonNumber: 1,
            episodeNumber: 1,
            name: 'Pilot',
          ),
        ],
      );

      expect(season.label, 'Season 1');
      expect(season.episodes, hasLength(1));
    });
  });
}
