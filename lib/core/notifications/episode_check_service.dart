import 'package:flutter/foundation.dart';

import '../../data/models/catalogue_item.dart';
import '../../data/models/new_episode_alert.dart';
import '../../data/repositories/background_check_outbox.dart';
import '../../data/repositories/hive_user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import '../constants/app_constants.dart';
import '../network/network_feedback.dart';
import 'episode_notification_policy.dart';
import 'new_episode_checker.dart';
import 'notification_service.dart';

/// [shows] ordered by id, starting after [resumeAfterShowId] and wrapping.
@visibleForTesting
List<TvShow> rotateShowsAfter(List<TvShow> shows, int? resumeAfterShowId) {
  final sorted = [...shows]..sort((a, b) => a.id.compareTo(b.id));
  if (resumeAfterShowId == null) return sorted;
  final start = sorted.indexWhere((show) => show.id > resumeAfterShowId);
  if (start <= 0) return sorted;
  return [...sorted.sublist(start), ...sorted.sublist(0, start)];
}

/// Runs the periodic episode check from the background isolate.
class EpisodeCheckService {
  EpisodeCheckService._();

  /// Native periodic task: refreshes alerts and raises a system notification
  /// when the app is not in foreground. Eligible episodes aired recently,
  /// were not notified yet, and are not already in the catalogue.
  ///
  /// The UI isolate owns the user-data boxes: this only reads a snapshot of
  /// them and writes its result to [BackgroundCheckOutbox].
  static Future<void> runNativeBackgroundCheck({
    required TmdbService tmdbService,
  }) async {
    final snapshot = await HiveUserDataStore.readSnapshot();
    if (snapshot == null) return;

    final outbox = await BackgroundCheckOutbox.openForWriting();
    try {
      await checkAndStore(
        snapshot: snapshot,
        tmdbService: tmdbService,
        outbox: outbox,
        notify: (count) =>
            NotificationService().showNewEpisodesNotification(count: count),
      );
    } finally {
      await outbox.close();
    }
  }

  /// Checks the followed shows of [snapshot] block by block, saving to
  /// [outbox] after each block.
  ///
  /// The OS may end a background run at any time (about 30 s on iOS): what
  /// the completed blocks found is kept, shows not reached keep their previous
  /// alert, and the next run resumes after the last show checked.
  @visibleForTesting
  static Future<void> checkAndStore({
    required UserDataSnapshot snapshot,
    required TmdbService tmdbService,
    required BackgroundCheckOutbox outbox,
    required Future<void> Function(int count) notify,
    int blockSize = AppConstants.episodeCheckBlockSize,
  }) async {
    final shows = rotateShowsAfter(
      [
        for (final item in snapshot.catalogue)
          if (item is TvShow && item.isFollowed) item,
      ],
      outbox.resumeAfterShowId,
    );
    final followedIds = {for (final show in shows) show.id};
    final catalogueEpisodeIds = {
      for (final record in snapshot.watchHistory)
        if (!record.isFilm && record.episodeId != null) record.episodeId!,
    };

    // Start from the newest alerts known: a previous run the app has not
    // imported yet, or the ones saved by the app.
    final previous = outbox.result;
    final lastLocalCheck = snapshot.lastEpisodeCheckAt;
    final baseAlerts = previous != null &&
            (lastLocalCheck == null ||
                previous.checkedAt.isAfter(lastLocalCheck))
        ? previous.alerts
        : snapshot.newEpisodeAlerts;
    var alerts = <NewEpisodeAlert>[
      for (final alert in baseAlerts)
        if (followedIds.contains(alert.showId) &&
            !catalogueEpisodeIds.contains(alert.episodeId))
          alert,
    ];
    // Fallback: versions without the outbox kept these ids in the UI-owned
    // meta box.
    var notified = outbox.notifiedEpisodeIds ?? snapshot.notifiedEpisodeIds;
    var notifiedCount = 0;

    if (shows.isEmpty) {
      await outbox.save(
        alerts: alerts,
        checkedAt: DateTime.now(),
        notifiedEpisodeIds: notified,
      );
      return;
    }

    final checker = NewEpisodeChecker(tmdbService: tmdbService);
    for (var start = 0; start < shows.length; start += blockSize) {
      final block = shows.sublist(
        start,
        (start + blockSize).clamp(0, shows.length),
      );
      final existing = alerts;
      // All followed shows: Continue Watching includes catch-up on Ended
      // series when a later season's episodes have already aired.
      final result = await NetworkFeedback.runSilent(
        () => checker.checkShows(
          shows: block,
          watchHistory: snapshot.watchHistory,
          forceRefresh: true,
          mergeWithExisting: true,
          existingAlerts: existing,
          persistAlerts: false,
        ),
      );
      alerts = result.allAlerts;

      if (!snapshot.appInForeground) {
        final eligible = alertsEligibleForSystemNotification(
          alerts: alerts,
          alreadyNotifiedEpisodeIds: notified,
          catalogueEpisodeIds: catalogueEpisodeIds,
        );
        if (eligible.isNotEmpty) {
          // One notification per run: later blocks update its count.
          notifiedCount += eligible.length;
          await notify(notifiedCount);
          // Drop IDs that are no longer in the current alert snapshot.
          final activeIds = {for (final alert in alerts) alert.episodeId};
          notified = {
            ...notified,
            for (final alert in eligible) alert.episodeId,
          }..removeWhere((id) => !activeIds.contains(id));
        }
      }

      await outbox.save(
        alerts: alerts,
        checkedAt: DateTime.now(),
        notifiedEpisodeIds: notified,
        resumeAfterShowId: block.last.id,
      );
    }
  }
}
