import '../../data/models/catalogue_item.dart';
import '../../data/repositories/background_check_outbox.dart';
import '../../data/repositories/hive_user_data_store.dart';
import '../../data/services/tmdb_service.dart';
import '../network/network_feedback.dart';
import 'episode_notification_policy.dart';
import 'new_episode_checker.dart';
import 'notification_service.dart';

/// Runs the periodic episode check from the background isolate.
class EpisodeCheckService {
  EpisodeCheckService._();

  /// Native periodic task: refreshes alerts and raises a system notification
  /// when the app is not in foreground. Eligible episodes aired today, were
  /// not notified yet, and are not already in the catalogue.
  ///
  /// The UI isolate owns the user-data boxes: this only reads a snapshot of
  /// them and writes its result to [BackgroundCheckOutbox].
  static Future<void> runNativeBackgroundCheck({
    required TmdbService tmdbService,
  }) async {
    final snapshot = await HiveUserDataStore.readSnapshot();
    if (snapshot == null) return;

    final followedShows = [
      for (final item in snapshot.catalogue)
        if (item is TvShow && item.isFollowed) item,
    ];
    final checkedAt = DateTime.now();

    // All followed shows: Continue Watching includes catch-up on Ended
    // series when a later season's episodes have already aired.
    final result = await NetworkFeedback.runSilent(
      () => NewEpisodeChecker(tmdbService: tmdbService).checkShows(
        shows: followedShows,
        watchHistory: snapshot.watchHistory,
        forceRefresh: true,
        existingAlerts: snapshot.newEpisodeAlerts,
        persistAlerts: false,
      ),
    );

    final outbox = await BackgroundCheckOutbox.openForWriting();
    try {
      // Fallback: versions without the outbox kept these ids in the UI-owned
      // meta box.
      var notified = outbox.notifiedEpisodeIds ?? snapshot.notifiedEpisodeIds;

      if (!snapshot.appInForeground) {
        final eligible = alertsEligibleForSystemNotification(
          alerts: result.allAlerts,
          alreadyNotifiedEpisodeIds: notified,
          catalogueEpisodeIds: {
            for (final record in snapshot.watchHistory)
              if (!record.isFilm && record.episodeId != null)
                record.episodeId!,
          },
        );
        if (eligible.isNotEmpty) {
          await NotificationService().showNewEpisodesNotification(
            count: eligible.length,
          );
          // Drop IDs that are no longer in the current alert snapshot.
          final activeIds = {
            for (final alert in result.allAlerts) alert.episodeId,
          };
          notified = {
            ...notified,
            for (final alert in eligible) alert.episodeId,
          }..removeWhere((id) => !activeIds.contains(id));
        }
      }

      await outbox.save(
        alerts: result.allAlerts,
        checkedAt: checkedAt,
        notifiedEpisodeIds: notified,
      );
    } finally {
      await outbox.close();
    }
  }
}
