import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/watch_record.dart';
import 'episode_signature.dart';

/// Whether [episode] is an available immediate-next: aired and not yet
/// registered in watch history. Callers must already ensure [episode] is the
/// immediate next S/E after the last registered episode.
bool isAvailableImmediateNextEpisode(
  EpisodeModel episode,
  List<WatchRecord> watchHistory,
) {
  return episode.hasAired &&
      !isEpisodeRegisteredInCatalogue(episode, watchHistory);
}

/// TMDB statuses that mean the series is still active (not concluded).
const Set<String> kOngoingSeriesStatuses = {
  'returning series',
  'planned',
  'in production',
  'pilot',
};

/// Whether a series is still in progress: ongoing TMDB status and/or a
/// scheduled next episode. Independent of the user's watch registration.
bool isSeriesInProgress({
  String? status,
  String? nextEpisodeAirDate,
}) {
  if (_hasScheduledNextEpisode(nextEpisodeAirDate)) return true;
  return isOngoingSeriesStatus(status);
}

/// Whether [show] is still airing or has an upcoming episode scheduled.
bool isShowInProgress(TvShow show) {
  return isSeriesInProgress(
    status: show.status,
    nextEpisodeAirDate: show.nextEpisodeAirDate,
  );
}

/// Whether a series should be included in new-episode monitoring.
///
/// Unknown/missing TMDB status fails open so unsynced catalogue items are
/// still checked; known concluded series without a next episode are skipped.
bool shouldMonitorSeriesForNewEpisodes({
  String? status,
  String? nextEpisodeAirDate,
}) {
  final normalized = status?.trim();
  if (normalized == null || normalized.isEmpty) return true;
  return isSeriesInProgress(
    status: status,
    nextEpisodeAirDate: nextEpisodeAirDate,
  );
}

/// Whether [show] should be included in new-episode monitoring.
bool shouldMonitorShowForNewEpisodes(TvShow show) {
  return shouldMonitorSeriesForNewEpisodes(
    status: show.status,
    nextEpisodeAirDate: show.nextEpisodeAirDate,
  );
}

/// True for TMDB lifecycle statuses that are not Ended/Canceled.
bool isOngoingSeriesStatus(String? status) {
  final normalized = status?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return false;
  return kOngoingSeriesStatuses.contains(normalized);
}

bool _hasScheduledNextEpisode(String? nextEpisodeAirDate) {
  final raw = nextEpisodeAirDate?.trim();
  return raw != null && raw.isNotEmpty;
}
