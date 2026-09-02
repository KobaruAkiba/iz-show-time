import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';
import '../../data/models/watch_record.dart';
import '../../data/repositories/user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import 'episode_signature.dart';

/// Result of checking catalogue TV shows for newly aired episodes.
class NewEpisodeCheckResult {
  final List<NewEpisodeAlert> newlyDetected;
  final List<NewEpisodeAlert> allAlerts;

  const NewEpisodeCheckResult({
    required this.newlyDetected,
    required this.allAlerts,
  });
}

/// Checks catalogue TV shows against TMDB using the last registered S/E in
/// watch history as the baseline for new episode detection.
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
      final showAlerts = await _checkShow(
        show: show,
        watchHistory: watchHistory,
        checkedAt: now,
      );

      for (final alert in showAlerts) {
        final previous = existingByEpisodeId[alert.episodeId];
        if (previous == null) {
          newlyDetected.add(alert);
          allAlerts.add(alert);
        } else {
          allAlerts.add(previous);
        }
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

  Future<List<NewEpisodeAlert>> _checkShow({
    required TvShow show,
    required List<WatchRecord> watchHistory,
    required DateTime checkedAt,
  }) async {
    final lastRegistered = lastRegisteredEpisodeForShow(show.id, watchHistory);
    if (lastRegistered == null) return const [];

    final details = await _tmdbService.getMediaDetails(show);
    final seasonCount = details?.numberOfSeasons ?? 0;
    if (seasonCount <= 0) return const [];

    final airedEpisodes = await _fetchAiredEpisodes(
      tvId: show.id,
      seasonCount: seasonCount,
    );

    return airedEpisodes
        .where(
          (episode) =>
              episode.hasAired &&
              isEpisodeAfterSignature(episode, lastRegistered) &&
              !isEpisodeRegisteredInCatalogue(episode, watchHistory),
        )
        .map(
          (episode) => NewEpisodeAlert(
            showId: show.id,
            showTitle: show.title,
            showPosterPath: show.posterPath,
            episodeId: episode.id,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber,
            episodeName: episode.displayTitle,
            airDate: episode.airDate,
            detectedAt: checkedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<List<EpisodeModel>> _fetchAiredEpisodes({
    required int tvId,
    required int seasonCount,
  }) async {
    final aired = <EpisodeModel>[];

    for (var season = 1; season <= seasonCount; season++) {
      final episodes = await _tmdbService.getSeasonEpisodes(
        tvId: tvId,
        seasonNumber: season,
        forceRefresh: true,
      );
      aired.addAll(episodes.where((episode) => episode.hasAired));
    }

    return aired;
  }
}
