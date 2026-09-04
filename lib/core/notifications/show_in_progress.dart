import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';
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

/// Whether [showId] has an immediate next aired episode available, based on
/// the latest [NewEpisodeAlert] snapshot (same source as Home New Episodes).
bool isShowInProgress(
  int showId, {
  required Iterable<NewEpisodeAlert> alerts,
}) {
  for (final alert in alerts) {
    if (alert.showId == showId) return true;
  }
  return false;
}

/// Show IDs currently considered in progress (immediate next episode available).
Set<int> inProgressShowIds({
  required Iterable<NewEpisodeAlert> alerts,
}) {
  return {for (final alert in alerts) alert.showId};
}
