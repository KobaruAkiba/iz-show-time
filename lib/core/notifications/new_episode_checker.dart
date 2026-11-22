import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/new_episode_alert.dart';
import '../../data/models/tv_show_summary.dart';
import '../../data/models/watch_record.dart';
import '../../data/repositories/user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import '../constants/app_constants.dart';
import '../network/api_error.dart';
import '../utils/catalogue_activity.dart';
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
    UserDataStore? userDataStore,
  })  : _tmdbService = tmdbService,
        _userDataStore = userDataStore;

  final TmdbService _tmdbService;

  /// Null when the caller owns persistence (background isolate).
  final UserDataStore? _userDataStore;

  /// Checks [shows] and optionally persists alerts.
  ///
  /// When [mergeWithExisting] is true, alerts for shows not in [shows] are kept
  /// from [existingAlerts] (or the store when that is null).
  /// Use [forceRefresh] for background/network freshness; UI paths should leave
  /// it false so TMDB cache is reused.
  /// Set [persistAlerts] to false when the caller will commit/persist after
  /// reconciling concurrent refreshes.
  Future<NewEpisodeCheckResult> checkShows({
    required List<TvShow> shows,
    required List<WatchRecord> watchHistory,
    bool forceRefresh = false,
    bool mergeWithExisting = false,
    List<NewEpisodeAlert>? existingAlerts,
    bool persistAlerts = true,
  }) async {
    final store = _userDataStore;
    await store?.open();

    final priorAlerts = existingAlerts ??
        await store?.loadNewEpisodeAlerts() ??
        const <NewEpisodeAlert>[];
    final existingByEpisodeId = {
      for (final alert in priorAlerts) alert.episodeId: alert,
    };
    final priorByShowId = {
      for (final alert in priorAlerts) alert.showId: alert,
    };
    final now = DateTime.now();

    Future<NewEpisodeAlert?> checkShow(TvShow show) async {
      try {
        return await _findImmediateNextAlert(
          show: show,
          watchHistory: watchHistory,
          checkedAt: now,
          forceRefresh: forceRefresh,
          priorAlert: priorByShowId[show.id],
        );
      } on ApiException catch (error) {
        // Keep the show's previous alert on failure; other shows still process.
        return _alertKeptOnFailure(
          error,
          priorByShowId[show.id],
          watchHistory,
        );
      }
    }

    // Bounded parallelism; results keep the order of [shows].
    final nextAlerts = <NewEpisodeAlert?>[];
    const concurrency = AppConstants.episodeCheckConcurrency;
    for (var start = 0; start < shows.length; start += concurrency) {
      final end = (start + concurrency).clamp(0, shows.length);
      nextAlerts.addAll(
        await Future.wait([
          for (var index = start; index < end; index++)
            checkShow(shows[index]),
        ]),
      );
    }

    final checkedAlerts = nextAlerts.whereType<NewEpisodeAlert>().toList();
    final newlyDetected = [
      for (final alert in checkedAlerts)
        if (!existingByEpisodeId.containsKey(alert.episodeId)) alert,
    ];

    final List<NewEpisodeAlert> allAlerts;
    if (mergeWithExisting) {
      final checkedShowIds = {for (final show in shows) show.id};
      allAlerts = [
        ...priorAlerts.where((alert) => !checkedShowIds.contains(alert.showId)),
        ...checkedAlerts,
      ];
    } else {
      allAlerts = checkedAlerts;
    }

    final lastActivity = lastCatalogueActivityByMediaId(watchHistory);
    allAlerts.sort(
      (a, b) => compareContinueWatchingAlerts(a, b, lastActivity),
    );

    if (persistAlerts && store != null) {
      await store.saveNewEpisodeAlerts(allAlerts);
      await store.saveLastEpisodeCheckAt(now);
    }

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
    NewEpisodeAlert? priorAlert,
  }) async {
    final lastRegistered = lastRegisteredEpisodeForShow(show.id, watchHistory);
    if (lastRegistered == null) return null;

    // Continue Watching is catch-up (next aired S/E), not "still airing" —
    // Ended/Canceled shows must still surface when a later season is available.
    final details = await _tmdbService.getTvShowSummary(
      show.id,
      forceRefresh: forceRefresh,
    );
    // If details are missing, still probe at least the next season after progress.
    final seasonCount = details?.numberOfSeasons ??
        (lastRegistered.seasonNumber + 1);
    if (seasonCount <= 0) return null;
    if (_isCaughtUp(details, lastRegistered, seasonCount, checkedAt)) {
      return null;
    }

    final next = await _findImmediateNextEpisode(
      tvId: show.id,
      lastRegistered: lastRegistered,
      seasonCount: seasonCount,
      forceRefresh: forceRefresh,
    );

    final fallbackRuntime = details?.averageEpisodeRuntimeMinutes ??
        next?.peerAverageRuntime;
    final nextEpisode = next?.episode;
    final addable = nextEpisode != null &&
        isAvailableImmediateNextEpisode(
          nextEpisode,
          watchHistory,
          fallbackRuntimeMinutes: fallbackRuntime,
        );
    if (nextEpisode == null || !addable) {
      return null;
    }

    final resolvedRuntime = nextEpisode.resolvedRuntimeMinutes(
      fallbackRuntimeMinutes: fallbackRuntime,
    );

    final resolvedPoster = _nonEmptyPosterPath(details?.posterPath) ??
        _nonEmptyPosterPath(show.posterPath) ??
        _nonEmptyPosterPath(priorAlert?.showPosterPath);

    return NewEpisodeAlert(
      showId: show.id,
      showTitle: show.title,
      showPosterPath: resolvedPoster,
      episodeId: nextEpisode.id,
      seasonNumber: nextEpisode.seasonNumber,
      episodeNumber: nextEpisode.episodeNumber,
      episodeName: nextEpisode.displayTitle,
      airDate: nextEpisode.airDate,
      runtimeMinutes: resolvedRuntime,
      detectedAt: checkedAt,
      laterAiredEpisodes: [
        for (final episode in next!.seasonEpisodes)
          if (episode.episodeNumber > nextEpisode.episodeNumber &&
              episode.airDate != null &&
              !EpisodeModel.isAirDateUpcoming(episode.airDate!, now: checkedAt))
            LaterAiredEpisode(
              episodeId: episode.id,
              airDate: episode.airDate!,
            ),
      ],
    );
  }

  /// The alert to keep for a show whose check failed with [error].
  ///
  /// A transient error is not a verdict: dropping [prior] would hide the
  /// Continue Watching row and notify its episode again on the next run.
  /// A show TMDB no longer has, or an episode already registered, drops it.
  static NewEpisodeAlert? _alertKeptOnFailure(
    ApiException error,
    NewEpisodeAlert? prior,
    List<WatchRecord> watchHistory,
  ) {
    if (prior == null || error.type == ApiErrorType.notFound) return null;
    final alreadyRegistered = watchHistory.any(
      (record) => !record.isFilm && record.episodeId == prior.episodeId,
    );
    return alreadyRegistered ? null : prior;
  }

  /// True when TMDB already says nothing aired after [lastRegistered], so the
  /// season requests can be skipped.
  ///
  /// Only decided inside the last season: a later season is always probed,
  /// as its first episode may surface without an air date.
  static bool _isCaughtUp(
    TvShowSummary? summary,
    EpisodeSignature lastRegistered,
    int seasonCount,
    DateTime now,
  ) {
    final lastAired = summary?.lastAiredEpisode;
    // Specials (season 0) say nothing about regular-season progress.
    if (summary == null || lastAired == null || lastAired.seasonNumber < 1) {
      return false;
    }
    if (lastRegistered.seasonNumber < seasonCount) return false;
    if (compareEpisodeSignatures(lastAired, lastRegistered) > 0) return false;

    final nextRaw = summary.nextEpisodeAirDate;
    if (nextRaw == null) return true;
    final nextDate = EpisodeModel.parseAirDate(nextRaw);
    if (nextDate == null) return false;
    // An episode airing today may not be in `last_episode_to_air` yet.
    return EpisodeModel.isAirDateUpcoming(nextDate, now: now);
  }

  /// Prefers a non-empty TMDB path; treats blank strings as missing.
  static String? _nonEmptyPosterPath(String? path) {
    if (path == null || path.isEmpty) return null;
    return path;
  }

  /// The next episode, with the season it was found in.
  Future<
      ({
        EpisodeModel episode,
        int? peerAverageRuntime,
        List<EpisodeModel> seasonEpisodes,
      })?> _findImmediateNextEpisode({
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
      if (nextInSeason != null) {
        return (
          episode: nextInSeason,
          peerAverageRuntime: EpisodeModel.averagePositiveRuntimeMinutes(
            seasonEpisodes,
            excludeEpisodeId: nextInSeason.id,
          ),
          seasonEpisodes: seasonEpisodes,
        );
      }
    }

    final nextSeason = lastRegistered.seasonNumber + 1;
    if (nextSeason > seasonCount) return null;

    final nextSeasonEpisodes = await _tmdbService.getSeasonEpisodes(
      tvId: tvId,
      seasonNumber: nextSeason,
      forceRefresh: forceRefresh,
    );
    // Prefer the first dated episode so undated E1 stubs don't block S2E2, etc.
    final nextEpisode = _nextDatedEpisodeAfter(
          nextSeasonEpisodes,
          afterEpisodeNumber: 0,
        ) ??
        _episodeWithNumber(nextSeasonEpisodes, 1);
    if (nextEpisode == null) return null;
    return (
      episode: nextEpisode,
      peerAverageRuntime: EpisodeModel.averagePositiveRuntimeMinutes(
        nextSeasonEpisodes,
        excludeEpisodeId: nextEpisode.id,
      ),
      seasonEpisodes: nextSeasonEpisodes,
    );
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
