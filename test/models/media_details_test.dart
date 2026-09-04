import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/media_details.dart';

void main() {
  group('MediaDetails.fromTmdbJson film', () {
    test('parses base fields and append_to_response payload', () {
      final details = MediaDetails.fromTmdbJson(
        {
          'title': 'Fight Club',
          'overview': 'An insomniac office worker...',
          'tagline': 'Mischief. Mayhem. Soap.',
          'status': 'Released',
          'runtime': 139,
          'release_date': '1999-10-15',
          'poster_path': '/poster.jpg',
          'backdrop_path': '/backdrop.jpg',
          'homepage': 'https://example.com',
          'original_language': 'en',
          'vote_average': 8.4,
          'vote_count': 26000,
          'imdb_id': 'tt0137523',
          'genres': [
            {'id': 18, 'name': 'Drama'},
            {'id': 53, 'name': 'Thriller'},
          ],
          'credits': {
            'cast': [
              {
                'name': 'Brad Pitt',
                'character': 'Tyler Durden',
                'profile_path': '/pitt.jpg',
              },
              {
                'name': 'Edward Norton',
                'character': 'The Narrator',
              },
            ],
            'crew': [
              {'name': 'David Fincher', 'job': 'Director'},
              {'name': 'Jim Uhls', 'job': 'Screenplay'},
            ],
          },
          'keywords': {
            'keywords': [
              {'id': 1, 'name': 'dual identity'},
              {'id': 2, 'name': 'rage'},
            ],
          },
          'external_ids': {'imdb_id': 'tt0137523'},
          'release_dates': {
            'results': [
              {
                'iso_3166_1': 'US',
                'release_dates': [
                  {'certification': 'R', 'type': 3},
                ],
              },
            ],
          },
          'watch/providers': {
            'results': {
              'US': {
                'flatrate': [
                  {'provider_name': 'Disney Plus'},
                ],
                'rent': [
                  {'provider_name': 'Amazon Video'},
                ],
              },
            },
          },
          'recommendations': {
            'results': [
              {
                'id': 807,
                'title': 'Se7en',
                'poster_path': '/se7en.jpg',
              },
            ],
          },
          'similar': {
            'results': [
              {
                'id': 680,
                'title': 'Pulp Fiction',
                'poster_path': '/pf.jpg',
              },
            ],
          },
          'alternative_titles': {
            'titles': [
              {'title': 'El club de la lucha'},
            ],
          },
          'reviews': {
            'total_results': 12,
            'results': [
              {'author': 'A', 'content': '...'},
            ],
          },
        },
        isFilm: true,
      );

      expect(details.title, 'Fight Club');
      expect(details.isFilm, isTrue);
      expect(details.tagline, 'Mischief. Mayhem. Soap.');
      expect(details.status, 'Released');
      expect(details.runtimeMinutes, 139);
      expect(details.year, 1999);
      expect(details.director, 'David Fincher');
      expect(details.genres, ['Drama', 'Thriller']);
      expect(details.cast, hasLength(2));
      expect(details.cast.first.name, 'Brad Pitt');
      expect(details.cast.first.character, 'Tyler Durden');
      expect(details.certification, 'R');
      expect(details.keywordNames, ['dual identity', 'rage']);
      expect(details.imdbId, 'tt0137523');
      expect(details.watchProviderNames, containsAll(['Disney Plus', 'Amazon Video']));
      expect(details.related, hasLength(2));
      expect(details.related.first.title, 'Se7en');
      expect(details.reviewCount, 12);
      expect(details.alternativeTitles, ['El club de la lucha']);
      expect(details.backdropPath, '/backdrop.jpg');
      expect(details.formattedRuntime, '2h 19m');
    });
  });

  group('MediaDetails.fromTmdbJson tv', () {
    test('parses TV base fields and append payload', () {
      final details = MediaDetails.fromTmdbJson(
        {
          'name': 'Game of Thrones',
          'overview': 'Nine noble families...',
          'status': 'Ended',
          'number_of_seasons': 8,
          'number_of_episodes': 73,
          'episode_run_time': [60, 55],
          'first_air_date': '2011-04-17',
          'last_air_date': '2019-05-19',
          'next_episode_to_air': null,
          'poster_path': '/got.jpg',
          'created_by': [
            {'name': 'David Benioff'},
            {'name': 'D. B. Weiss'},
          ],
          'genres': [
            {'id': 10765, 'name': 'Sci-Fi & Fantasy'},
          ],
          'networks': [
            {'id': 49, 'name': 'HBO'},
          ],
          'aggregate_credits': {
            'cast': [
              {
                'name': 'Emilia Clarke',
                'roles': [
                  {'character': 'Daenerys Targaryen'},
                ],
                'profile_path': '/emilia.jpg',
              },
            ],
          },
          'content_ratings': {
            'results': [
              {'iso_3166_1': 'US', 'rating': 'TV-MA'},
              {'iso_3166_1': 'GB', 'rating': '15'},
            ],
          },
          'keywords': {
            'results': [
              {'id': 1, 'name': 'based on novel or book'},
            ],
          },
          'external_ids': {
            'imdb_id': 'tt0944947',
            'tvdb_id': 121361,
          },
          'watch/providers': {
            'results': {
              'US': {
                'flatrate': [
                  {'provider_name': 'Max'},
                ],
              },
            },
          },
          'recommendations': {
            'results': [
              {
                'id': 1396,
                'name': 'Breaking Bad',
                'poster_path': '/bb.jpg',
              },
            ],
          },
          'similar': {'results': []},
          'alternative_titles': {
            'results': [
              {'title': 'Il Trono di Spade'},
            ],
          },
          'reviews': {
            'total_results': 5,
            'results': [],
          },
          'episode_groups': {
            'results': [
              {
                'id': 'abc',
                'name': 'Original air dates',
                'type': 1,
              },
            ],
          },
        },
        isFilm: false,
      );

      expect(details.title, 'Game of Thrones');
      expect(details.isFilm, isFalse);
      expect(details.numberOfSeasons, 8);
      expect(details.numberOfEpisodes, 73);
      expect(details.averageEpisodeRuntimeMinutes, 57);
      expect(details.director, 'David Benioff, D. B. Weiss');
      expect(details.networkNames, ['HBO']);
      expect(details.lastAirDate, '2019-05-19');
      expect(details.cast.single.name, 'Emilia Clarke');
      expect(details.cast.single.character, 'Daenerys Targaryen');
      expect(details.certification, 'TV-MA');
      expect(details.keywordNames, ['based on novel or book']);
      expect(details.imdbId, 'tt0944947');
      expect(details.tvdbId, 121361);
      expect(details.watchProviderNames, ['Max']);
      expect(details.related.single.title, 'Breaking Bad');
      expect(details.related.single.isFilm, isFalse);
      expect(details.reviewCount, 5);
      expect(details.alternativeTitles, ['Il Trono di Spade']);
      expect(details.episodeGroups.single.name, 'Original air dates');
      expect(details.formattedSeasons, '8 seasons');
    });
  });
}
