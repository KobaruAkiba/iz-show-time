import '../../data/models/new_episode_alert.dart';
import 'episode_notification_policy.dart';

/// What the new episodes notification reports: how many episodes and the
/// shows they belong to.
class NewEpisodesSummary {
  const NewEpisodesSummary({
    required this.episodeCount,
    required this.showTitles,
  });

  final int episodeCount;

  /// Distinct, non-empty show titles, in alert order.
  final List<String> showTitles;
}

/// Summarizes [episodeIds] using [alerts] for the show titles.
///
/// Every id counts, but only ids still referred to by an alert add a title:
/// an alert dropped since the episode was notified has no title to show.
NewEpisodesSummary summarizeNotifiedEpisodes({
  required Iterable<int> episodeIds,
  required Iterable<NewEpisodeAlert> alerts,
}) {
  final ids = episodeIds.toSet();
  final titles = <String>{
    for (final alert in alerts)
      if (alert.showTitle.isNotEmpty &&
          alertEpisodeIds(alert).any(ids.contains))
        alert.showTitle,
  };
  return NewEpisodesSummary(
    episodeCount: ids.length,
    showTitles: titles.toList(),
  );
}
