import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/network/api_error.dart';
import 'package:iz_show_time_tracker/data/models/season_model.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

/// Fails the seasons listed in [failingSeasons]; the others load empty.
class _SeasonStubTmdbService extends TmdbService {
  _SeasonStubTmdbService({required this.failingSeasons})
      : super(cacheManager: null);

  final Set<int> failingSeasons;

  @override
  Future<SeasonModel?> getSeason({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    if (failingSeasons.contains(seasonNumber)) {
      throw const ApiException(ApiErrorType.notFound, 'missing season');
    }
    return SeasonModel(
      seasonNumber: seasonNumber,
      airDate: DateTime(2020, seasonNumber),
      episodes: const [],
    );
  }
}

void main() {
  group('TmdbService.getTvSeasons', () {
    test('keeps the other seasons when one fails', () async {
      final service = _SeasonStubTmdbService(failingSeasons: {2});

      final seasons = await service.getTvSeasons(tvId: 1, numberOfSeasons: 3);

      expect(seasons.map((season) => season.seasonNumber), [1, 2, 3]);
      expect(seasons[0].airDate, DateTime(2020));
      expect(seasons[1].airDate, isNull);
      expect(seasons[1].episodes, isEmpty);
    });

    test('reports the error when every season fails', () async {
      final service = _SeasonStubTmdbService(failingSeasons: {1, 2});

      await expectLater(
        service.getTvSeasons(tvId: 1, numberOfSeasons: 2),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
