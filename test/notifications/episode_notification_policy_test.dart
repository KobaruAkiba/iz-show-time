import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/episode_notification_policy.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';

void main() {
  group('EpisodeModel calendar helpers', () {
    test('isAiredToday is true only on the local air calendar day', () {
      final now = DateTime(2026, 3, 15, 18, 30);
      expect(
        EpisodeModel.isAiredToday(DateTime(2026, 3, 15), now: now),
        isTrue,
      );
      expect(
        EpisodeModel.isAiredToday(DateTime(2026, 3, 14), now: now),
        isFalse,
      );
      expect(EpisodeModel.isAiredToday(null, now: now), isFalse);
    });
  });

  group('alertsEligibleForSystemNotification', () {
    NewEpisodeAlert alert({
      required int episodeId,
      required DateTime? airDate,
      int? runtimeMinutes,
    }) {
      return NewEpisodeAlert(
        showId: 1,
        showTitle: 'Show',
        episodeId: episodeId,
        seasonNumber: 1,
        episodeNumber: episodeId,
        episodeName: 'Ep $episodeId',
        airDate: airDate,
        runtimeMinutes: runtimeMinutes,
        detectedAt: DateTime(2026, 3, 15),
      );
    }

    test('includes catalogue-addable alerts that were not notified yet', () {
      final now = DateTime(2026, 3, 15, 21);
      final eligible = alertsEligibleForSystemNotification(
        alerts: [
          alert(
            episodeId: 1,
            airDate: DateTime(2026, 3, 15),
            runtimeMinutes: 42,
          ),
          alert(
            episodeId: 2,
            airDate: DateTime(2026, 3, 14),
            runtimeMinutes: 42,
          ),
          alert(
            episodeId: 3,
            airDate: DateTime(2026, 3, 15),
            runtimeMinutes: 42,
          ),
          alert(episodeId: 4, airDate: null, runtimeMinutes: 42),
          alert(
            episodeId: 5,
            airDate: DateTime(2026, 3, 15),
            runtimeMinutes: null,
          ),
        ],
        alreadyNotifiedEpisodeIds: {3},
        now: now,
      );

      expect(eligible.map((a) => a.episodeId), [1, 2, 4]);
    });

    test('excludes upcoming and missing-runtime alerts', () {
      final eligible = alertsEligibleForSystemNotification(
        alerts: [
          alert(
            episodeId: 1,
            airDate: DateTime(2099, 6, 1),
            runtimeMinutes: 42,
          ),
          alert(
            episodeId: 2,
            airDate: DateTime(2026, 3, 10),
            runtimeMinutes: null,
          ),
        ],
        alreadyNotifiedEpisodeIds: {},
        now: DateTime(2026, 3, 15),
      );

      expect(eligible, isEmpty);
    });

    test('excludes catalogue-addable alerts already in the catalogue', () {
      final now = DateTime(2026, 3, 15, 21);
      final eligible = alertsEligibleForSystemNotification(
        alerts: [
          alert(
            episodeId: 1,
            airDate: DateTime(2026, 3, 15),
            runtimeMinutes: 42,
          ),
          alert(
            episodeId: 2,
            airDate: DateTime(2026, 3, 15),
            runtimeMinutes: 42,
          ),
        ],
        alreadyNotifiedEpisodeIds: {},
        catalogueEpisodeIds: {2},
        now: now,
      );

      expect(eligible.map((a) => a.episodeId), [1]);
    });
  });
}
