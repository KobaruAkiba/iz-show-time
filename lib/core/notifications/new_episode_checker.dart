import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';
import '../../data/models/watch_record.dart';
import '../../data/repositories/user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import '../network/api_error.dart';
import 'episode_signature.dart';
import 'show_in_progress.dart';

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

  /// Checks [shows] and persists alerts.
  ///
  /// When [mergeWithExisting] is true, alerts for shows not in [shows] are kept.
  /// Use [forceRefresh] for background/network freshness; UI paths should leave
  /// it false so TMDB cache is reused.
  Future<NewEpisodeCheckResult> checkShows({
    required List<TvShow> shows,
    required List<WatchRecord> watchHistory,
    bool forceRefresh = false,
    bool mergeWithExisting = false,
  }) async {
    await _userDataStore.open();

    final existingAlerts = await _userDataStore.loadNewEpisodeAlerts();
    final existingByEpisodeId = {
      for (final alert in existingAlerts) alert.episodeId: alert,
    };
    final newlyDetected = <NewEpisodeAlert>[];
    final checkedAlerts = <NewEpisodeAlert>[];
    final now = DateTime.now();

    for (final show in shows) {
      try {
        final nextAlert = await _findImmediateNextAlert(
          show: show,
          watchHistory: watchHistory,
          checkedAt: now,
          forceRefresh: forceRefresh,
        );
        if (nextAlert == null) continue;

        checkedAlerts.add(nextAlert);
        if (!existingByEpisodeId.containsKey(nextAlert.episodeId)) {
          newlyDetected.add(nextAlert);
        }
      } on ApiException {
        // Skip this show on network/API failure; other shows still process.
        continue;
      }
    }

    final List<NewEpisodeAlert> allAlerts;
    if (mergeWithExisting) {
      final checkedShowIds = {for (final show in shows) show.id};
      allAlerts = [
        ...existingAlerts.where((alert) => !checkedShowIds.contains(alert.showId)),
        ...checkedAlerts,
      ];
    } else {
      allAlerts = checkedAlerts;
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
    required bool forceRefresh,
  }) async {
    final lastRegistered = lastRegisteredEpisodeForShow(show.id, watchHistory);
    if (lastRegistered == null) return null;

    // Continue Watching is catch-up (next aired S/E), not "still airing" —
    // Ended/Canceled shows must still surface when a later season is available.
    final details = await _tmdbService.getMediaDetails(show);
    // If details are missing, still probe at least the next season after progress.
    final seasonCount = details?.numberOfSeasons ??
        (lastRegistered.seasonNumber + 1);
    if (seasonCount <= 0) return null;

    final nextEpisode = await _findImmediateNextEpisode(
      tvId: show.id,
      lastRegistered: lastRegistered,
      seasonCount: seasonCount,
      forceRefresh: forceRefresh,
    );

    if (nextEpisode == null ||
        !isAvailableImmediateNextEpisode(nextEpisode, watchHistory)) {
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
    required bool forceRefresh,
  }) async {
    if (lastRegistered.seasonNumber <= seasonCount) {
      final seasonEpisodes = await _tmdbService.getSeasonEpisodes(
        tvId: tvId,
        seasonNumber: lastRegistered.seasonNumber,
        forceRefresh: forceRefresh,
      );
      final nextInSeason = _nextDatedEpisodeAfter(
        seasonEpisodes,
        afterEpisodeNumber: lastRegistered.episodeNumber,
      );
      // Dated next ep (aired or upcoming): stay in-season.
      // Undated TMDB stubs are skipped so we can cross to the next season.
      if (nextInSeason != null) return nextInSeason;
    }

    final nextSeason = lastRegistered.seasonNumber + 1;
    if (nextSeason > seasonCount) return null;

    final nextSeasonEpisodes = await _tmdbService.getSeasonEpisodes(
      tvId: tvId,
      seasonNumber: nextSeason,
      forceRefresh: forceRefresh,
    );
    // Prefer the first dated episode so undated E1 stubs don't block S2E2, etc.
    return _nextDatedEpisodeAfter(
          nextSeasonEpisodes,
          afterEpisodeNumber: 0,
        ) ??
        _episodeWithNumber(nextSeasonEpisodes, 1);
  }

  /// First episode after [afterEpisodeNumber] that has an air date (aired or
  /// upcoming). Undated stubs are ignored so season-crossing can proceed.
  EpisodeModel? _nextDatedEpisodeAfter(
    List<EpisodeModel> episodes, {
    required int afterEpisodeNumber,
  }) {
    EpisodeModel? best;
    for (final episode in episodes) {
      if (episode.episodeNumber <= afterEpisodeNumber) continue;
      if (episode.airDate == null) continue;
      if (best == null || episode.episodeNumber < best.episodeNumber) {
        best = episode;
      }
    }
    return best;
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
