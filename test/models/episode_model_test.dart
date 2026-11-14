import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';

void main() {
  group('EpisodeModel runtime fallback', () {
    EpisodeModel episode({int? runtime}) => EpisodeModel.fromJson({
          'id': 1,
          'season_number': 1,
          'episode_number': 1,
          'name': 'Pilot',
          'air_date': '2020-01-01',
          'runtime': runtime,
        });

    test('treats a zero runtime as missing', () {
      final zero = episode(runtime: 0);

      expect(zero.resolvedRuntimeMinutes(fallbackRuntimeMinutes: 45), 45);
      expect(zero.isCatalogueAddable(fallbackRuntimeMinutes: 45), isTrue);
      expect(zero.isCatalogueAddable(), isFalse);
      expect(
        EpisodeModel.isCatalogueAddableFields(
          airDate: DateTime(2020),
          runtimeMinutes: 0,
          fallbackRuntimeMinutes: 45,
        ),
        isTrue,
      );
    });

    test('prefers the episode runtime over the fallback', () {
      expect(
        episode(runtime: 30).resolvedRuntimeMinutes(fallbackRuntimeMinutes: 45),
        30,
      );
    });
  });
}
