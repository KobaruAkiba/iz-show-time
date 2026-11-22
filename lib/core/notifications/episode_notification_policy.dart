import '../../data/models/episode_model.dart';
import '../constants/app_constants.dart';
import '../../data/models/new_episode_alert.dart';

/// Episode ids that should raise a one-shot system notification.
///
/// An alert qualifies only when its immediate-next episode is
/// catalogue-addable (not upcoming and with a resolved runtime) and not in the
/// catalogue yet. Legacy alerts without [NewEpisodeAlert.runtimeMinutes] do
/// not qualify until rewritten by the episode checker.
///
/// In a qualifying alert, the next episode and each of
/// [NewEpisodeAlert.laterAiredEpisodes] count on their own when aired one to
/// [AppConstants.notificationRecentAirDays] calendar days ago and neither
/// notified nor catalogued: catching up on an old show stays quiet, and
/// undated episodes cannot be called recent.
///
/// An episode aired today waits until the next day: TMDB air dates carry no
/// time of day, so it may not be available yet in the user's time zone.
List<int> episodesEligibleForSystemNotification({
  required Iterable<NewEpisodeAlert> alerts,
  required Set<int> alreadyNotifiedEpisodeIds,
  Set<int> catalogueEpisodeIds = const {},
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  bool eligible(int episodeId, DateTime? airDate) =>
      _airedRecently(airDate, today) &&
      !alreadyNotifiedEpisodeIds.contains(episodeId) &&
      !catalogueEpisodeIds.contains(episodeId);

  return [
    for (final alert in alerts)
      if (EpisodeModel.isCatalogueAddableFields(
            airDate: alert.airDate,
            runtimeMinutes: alert.runtimeMinutes,
            now: today,
          ) &&
          !catalogueEpisodeIds.contains(alert.episodeId)) ...[
        if (eligible(alert.episodeId, alert.airDate)) alert.episodeId,
        for (final later in alert.laterAiredEpisodes)
          if (eligible(later.episodeId, later.airDate)) later.episodeId,
      ],
  ];
}

/// Every episode id an alert refers to.
Iterable<int> alertEpisodeIds(NewEpisodeAlert alert) => [
      alert.episodeId,
      for (final later in alert.laterAiredEpisodes) later.episodeId,
    ];

bool _airedRecently(DateTime? airDate, DateTime now) {
  if (airDate == null) return false;
  // Calendar days: air dates carry no time of day. Today is excluded because
  // the episode may not be out yet in the user's time zone.
  final today = DateTime(now.year, now.month, now.day);
  final aired = DateTime(airDate.year, airDate.month, airDate.day);
  final days = today.difference(aired).inDays;
  return days >= 1 && days <= AppConstants.notificationRecentAirDays;
}
