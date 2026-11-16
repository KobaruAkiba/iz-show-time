import '../../data/models/catalogue_item.dart';
import '../../data/models/watch_record.dart';
import 'episode_signature.dart';

/// Latest registered S/E per show, built in a single pass over [watchHistory].
///
/// Records without season/episode numbers are skipped.
Map<int, EpisodeSignature> lastRegisteredEpisodesByShowId(
  Iterable<WatchRecord> watchHistory,
) {
  final result = <int, EpisodeSignature>{};
  for (final record in watchHistory) {
    if (record.isFilm) continue;
    final season = record.seasonNumber;
    final episode = record.episodeNumber;
    if (season == null || episode == null) continue;

    final current = (seasonNumber: season, episodeNumber: episode);
    final best = result[record.mediaId];
    if (best == null || compareEpisodeSignatures(current, best) > 0) {
      result[record.mediaId] = current;
    }
  }
  return result;
}

/// Whether [show] is caught up: no episode has aired after the latest one
/// registered in the catalogue.
///
/// Steps:
/// 1. Needs TMDB `last_episode_to_air` (synced on Catalogue activation).
/// 2. Needs at least one registered episode ([lastRegistered]).
/// 3. Caught up when [lastRegistered] is the same as or later than the last
///    aired S/E.
///
/// Missing data on either side → not caught up.
bool isShowCaughtUp(TvShow show, EpisodeSignature? lastRegistered) {
  final season = show.lastAiredSeasonNumber;
  final episode = show.lastAiredEpisodeNumber;
  if (season == null || episode == null || lastRegistered == null) {
    return false;
  }
  final lastAired = (seasonNumber: season, episodeNumber: episode);
  return compareEpisodeSignatures(lastRegistered, lastAired) >= 0;
}
