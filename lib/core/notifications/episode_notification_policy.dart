import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';

/// Alerts that should raise a one-shot system notification.
///
/// Only the immediate-next episode for a followed show qualifies, and only when
/// its TMDB [NewEpisodeAlert.airDate] is the local calendar day of [now].
/// Already-notified episode IDs are excluded so backlog / re-checks stay quiet.
List<NewEpisodeAlert> alertsEligibleForSystemNotification({
  required Iterable<NewEpisodeAlert> alerts,
  required Set<int> alreadyNotifiedEpisodeIds,
  DateTime? now,
}) {
  final moment = now ?? DateTime.now();
  return [
    for (final alert in alerts)
      if (EpisodeModel.isAiredToday(alert.airDate, now: moment) &&
          !alreadyNotifiedEpisodeIds.contains(alert.episodeId))
        alert,
  ];
}
