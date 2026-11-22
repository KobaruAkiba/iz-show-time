import '../../l10n/app_localizations.dart';
import 'new_episodes_summary.dart';

/// Body of the new episodes notification: names up to two shows and counts
/// the rest; without show titles it falls back to the generic text.
String newEpisodesNotificationBody(
  AppLocalizations l10n,
  NewEpisodesSummary summary,
) {
  final count = summary.episodeCount;
  return switch (summary.showTitles) {
    [] =>
      count == 1 ? l10n.notificationBodyOne : l10n.notificationBodyOther(count),
    [final show] => l10n.notificationBodyOneShow(count, show),
    [final first, final second] =>
      l10n.notificationBodyTwoShows(count, first, second),
    [final first, final second, ...final others] =>
      l10n.notificationBodyManyShows(count, first, second, others.length),
  };
}
