import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';

void main() {
  group('NewEpisodeAlert.showsNewBadge', () {
    NewEpisodeAlert alert({DateTime? airDate, int? runtimeMinutes}) {
      return NewEpisodeAlert(
        showId: 1,
        showTitle: 'Show',
        episodeId: 10,
        seasonNumber: 1,
        episodeNumber: 2,
        episodeName: 'Episode',
        airDate: airDate,
        runtimeMinutes: runtimeMinutes,
        detectedAt: DateTime(2026, 3, 15),
      );
    }

    test('is true when airDate is today', () {
      final today = DateTime.now();
      expect(
        alert(airDate: DateTime(today.year, today.month, today.day))
            .showsNewBadge,
        isTrue,
      );
    });

    test('is false when airDate is yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        alert(
          airDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        ).showsNewBadge,
        isFalse,
      );
    });

    test('is false when airDate is null', () {
      expect(alert(airDate: null).showsNewBadge, isFalse);
    });
  });

  group('NewEpisodeAlert runtime persistence', () {
    test('round-trips runtime_minutes in JSON', () {
      final alert = NewEpisodeAlert(
        showId: 1,
        showTitle: 'Show',
        episodeId: 10,
        seasonNumber: 1,
        episodeNumber: 2,
        episodeName: 'Episode',
        airDate: DateTime(2026, 3, 15),
        runtimeMinutes: 48,
        detectedAt: DateTime(2026, 3, 15, 12),
      );

      final restored = NewEpisodeAlert.fromJson(alert.toJson());
      expect(restored.runtimeMinutes, 48);
      expect(restored.isCatalogueAddable, isTrue);
    });

    test('legacy alerts without runtime_minutes are not catalogue-addable', () {
      final restored = NewEpisodeAlert.fromJson({
        'show_id': 1,
        'show_title': 'Show',
        'episode_id': 10,
        'season_number': 1,
        'episode_number': 2,
        'episode_name': 'Episode',
        'air_date': '2026-03-15T00:00:00.000',
        'detected_at': '2026-03-15T12:00:00.000',
      });

      expect(restored.runtimeMinutes, isNull);
      expect(restored.isCatalogueAddable, isFalse);
    });
  });
}
