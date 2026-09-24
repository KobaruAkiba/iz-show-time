import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';

void main() {
  group('NewEpisodeAlert.showsNewBadge', () {
    NewEpisodeAlert alert({DateTime? airDate}) {
      return NewEpisodeAlert(
        showId: 1,
        showTitle: 'Show',
        episodeId: 10,
        seasonNumber: 1,
        episodeNumber: 2,
        episodeName: 'Episode',
        airDate: airDate,
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
}
