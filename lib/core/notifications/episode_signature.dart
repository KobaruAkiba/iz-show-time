import '../../data/models/episode_model.dart';
import '../../data/models/watch_record.dart';

/// Season/episode pair used to compare catalogue progress (Sx Ey).
typedef EpisodeSignature = ({int seasonNumber, int episodeNumber});

/// Compares two S/E signatures. Returns positive when [a] is later than [b].
int compareEpisodeSignatures(EpisodeSignature a, EpisodeSignature b) {
  if (a.seasonNumber != b.seasonNumber) {
    return a.seasonNumber.compareTo(b.seasonNumber);
  }
  return a.episodeNumber.compareTo(b.episodeNumber);
}

/// Returns the latest S/E episode registered in the catalogue for [showId].
EpisodeSignature? lastRegisteredEpisodeForShow(
  int showId,
  List<WatchRecord> watchHistory,
) {
  WatchRecord? latest;

  for (final record in watchHistory) {
    if (record.isFilm || record.mediaId != showId) continue;

    final season = record.seasonNumber;
    final episode = record.episodeNumber;
    if (season == null || episode == null) continue;

    if (latest == null) {
      latest = record;
      continue;
    }

    final current = (
      seasonNumber: season,
      episodeNumber: episode,
    );
    final best = (
      seasonNumber: latest.seasonNumber!,
      episodeNumber: latest.episodeNumber!,
    );
    if (compareEpisodeSignatures(current, best) > 0) {
      latest = record;
    }
  }

  if (latest == null) return null;
  return (
    seasonNumber: latest.seasonNumber!,
    episodeNumber: latest.episodeNumber!,
  );
}

bool isEpisodeRegisteredInCatalogue(
  EpisodeModel episode,
  List<WatchRecord> watchHistory,
) {
  return watchHistory.any(
    (record) =>
        !record.isFilm &&
        record.episodeId == episode.id,
  );
}

bool isEpisodeAfterSignature(
  EpisodeModel episode,
  EpisodeSignature lastRegistered,
) {
  return EpisodeModel.compareBySeasonAndNumber(
        episode,
        lastRegistered.seasonNumber,
        lastRegistered.episodeNumber,
      ) >
      0;
}

/// Whether [episode] is exactly the next S/E after [lastRegistered].
bool isImmediateNextEpisode(
  EpisodeModel episode,
  EpisodeSignature lastRegistered,
) {
  if (episode.seasonNumber == lastRegistered.seasonNumber) {
    return episode.episodeNumber == lastRegistered.episodeNumber + 1;
  }
  if (episode.seasonNumber == lastRegistered.seasonNumber + 1) {
    return episode.episodeNumber == 1 &&
        lastRegistered.episodeNumber > 0;
  }
  return false;
}
