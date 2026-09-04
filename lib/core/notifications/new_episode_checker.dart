import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';
import '../../data/models/watch_record.dart';
import '../../data/repositories/user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import 'episode_signature.dart';

/// Result of checking catalogue shows for newly aired episodes.
class NewEpisodeCheckResult {
  final List<NewEpisodeAlert> newlyDetected;
  final List<NewEpisodeAlert> allAlerts;

  const NewEpisodeCheckResult({
    required this.newlyDetected,
    required this.allAlerts,
  });
}

/// Checks catalogue shows and surfaces only the immediate next episode
/// after the last registered S/E in watch history.
class NewEpisodeChecker {
  NewEpisodeChecker({
    required TmdbService tmdbService,
    required UserDataStore userDataStore,
  })  : _tmdbService = tmdbService,
        _userDataStore = userDataStore;

  final TmdbService _tmdbService;
  final UserDataStore _userDataStore;

  Future<NewEpisodeCheckResult> checkShows({
    required List<TvShow> shows,
    required List<WatchRecord> watchHistory,
  }) async {
    await _userDataStore.open();

    final existingAlerts = await _userDataStore.loadNewEpisodeAlerts();
    final existingByEpisodeId = {
      for (final alert in existingAlerts) alert.episodeId: alert,
    };
    final newlyDetected = <NewEpisodeAlert>[];
    final allAlerts = <NewEpisodeAlert>[];
    final now = DateTime.now();

    for (final show in shows) {
      final nextAlert = await _findImmediateNextAlert(
        show: show,
        watchHistory: watchHistory,
        checkedAt: now,
      );
      if (nextAlert == null) continue;

      allAlerts.add(nextAlert);
      if (!existingByEpisodeId.containsKey(nextAlert.episodeId)) {
        newlyDetected.add(nextAlert);
      }
    }

    allAlerts.sort(
      (a, b) => compareEpisodeSignatures(
        (seasonNumber: b.seasonNumber, episodeNumber: b.episodeNumber),
        (seasonNumber: a.seasonNumber, episodeNumber: a.episodeNumber),
      ),
    );

    await _userDataStore.saveNewEpisodeAlerts(allAlerts);
    await _userDataStore.saveLastEpisodeCheckAt(now);

    return NewEpisodeCheckResult(
      newlyDetected: newlyDetected,
      allAlerts: allAlerts,
    );
  }

  Future<NewEpisodeAlert?> _findImmediateNextAlert({
    required TvShow show,
    required List<WatchRecord> watchHistory,
    required DateTime checkedAt,
  }) async {
    final lastRegistered = lastRegisteredEpisodeForShow(show.id, watchHistory);
    if (lastRegistered == null) return null;

    final details = await _tmdbService.getMediaDetails(show);
    final seasonCount = details?.numberOfSeasons ?? 0;
    if (seasonCount <= 0) return null;

    final nextEpisode = await _findImmediateNextEpisode(
      tvId: show.id,
      lastRegistered: lastRegistered,
      seasonCount: seasonCount,
    );

    if (nextEpisode == null ||
        !nextEpisode.hasAired ||
        isEpisodeRegisteredInCatalogue(nextEpisode, watchHistory)) {
      return null;
    }

    return NewEpisodeAlert(
      showId: show.id,
      showTitle: show.title,
      showPosterPath: show.posterPath,
      episodeId: nextEpisode.id,
      seasonNumber: nextEpisode.seasonNumber,
      episodeNumber: nextEpisode.episodeNumber,
      episodeName: nextEpisode.displayTitle,
      airDate: nextEpisode.airDate,
      detectedAt: checkedAt,
    );
  }

  Future<EpisodeModel?> _findImmediateNextEpisode({
    required int tvId,
    required EpisodeSignature lastRegistered,
    required int seasonCount,
  }) async {
    if (lastRegistered.seasonNumber <= seasonCount) {
      final seasonEpisodes = await _tmdbService.getSeasonEpisodes(
        tvId: tvId,
        seasonNumber: lastRegistered.seasonNumber,
        forceRefresh: true,
      );
      final nextInSeason = _episodeWithNumber(
        seasonEpisodes,
        lastRegistered.episodeNumber + 1,
      );
      if (nextInSeason != null) return nextInSeason;
    }

    final nextSeason = lastRegistered.seasonNumber + 1;
    if (nextSeason > seasonCount) return null;

    final nextSeasonEpisodes = await _tmdbService.getSeasonEpisodes(
      tvId: tvId,
      seasonNumber: nextSeason,
      forceRefresh: true,
    );
    return _episodeWithNumber(nextSeasonEpisodes, 1);
  }

  EpisodeModel? _episodeWithNumber(
    List<EpisodeModel> episodes,
    int episodeNumber,
  ) {
    for (final episode in episodes) {
      if (episode.episodeNumber == episodeNumber) return episode;
    }
    return null;
  }
}
