import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';

/// Alerts that should raise a one-shot system notification.
///
/// Only the immediate-next episode for a followed show qualifies, and only when
/// it is catalogue-addable (not upcoming and with a resolved runtime).
/// Already-notified and already-catalogued episode IDs are excluded so backlog /
/// re-checks stay quiet. Legacy alerts without [NewEpisodeAlert.runtimeMinutes]
/// are not eligible until rewritten by the episode checker.
List<NewEpisodeAlert> alertsEligibleForSystemNotification({
  required Iterable<NewEpisodeAlert> alerts,
  required Set<int> alreadyNotifiedEpisodeIds,
  Set<int> catalogueEpisodeIds = const {},
  DateTime? now,
}) {
  return [
    for (final alert in alerts)
      if (EpisodeModel.isCatalogueAddableFields(
            airDate: alert.airDate,
            runtimeMinutes: alert.runtimeMinutes,
            now: now,
          ) &&
          !alreadyNotifiedEpisodeIds.contains(alert.episodeId) &&
          !catalogueEpisodeIds.contains(alert.episodeId))
        alert,
  ];
}
