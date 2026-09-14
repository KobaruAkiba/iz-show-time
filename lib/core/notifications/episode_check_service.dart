import '../network/network_feedback.dart';
import '../services/app_services.dart';
import 'episode_notification_policy.dart';
import 'new_episode_checker.dart';
import 'notification_service.dart';

/// Runs catalogue episode checks and optionally raises system notifications.
class EpisodeCheckService {
  EpisodeCheckService._();

  static Future<NewEpisodeCheckResult> checkCatalogue({
    required AppServices appServices,
  }) async {
    return NetworkFeedback.runSilent(() async {
      final checker = NewEpisodeChecker(
        tmdbService: appServices.tmdbService,
        userDataStore: appServices.userDataStore,
      );

      // All followed shows: Continue Watching includes catch-up on Ended
      // series when a later season's episodes have already aired.
      return checker.checkShows(
        shows: appServices.followedTvShows,
        watchHistory: appServices.watchHistory,
        forceRefresh: true,
      );
    });
  }

  /// Native periodic task: always refreshes alerts; OS notify only when the app
  /// is not in foreground (option B). Eligible episodes aired today, were not
  /// notified yet, and are not already in the catalogue.
  static Future<void> runNativeBackgroundCheck(AppServices appServices) async {
    final result = await checkCatalogue(appServices: appServices);
    appServices.updateNewEpisodeAlerts(result.allAlerts);

    final appIsOpen = await appServices.userDataStore.loadAppInForeground();
    if (appIsOpen) return;

    final alreadyNotified =
        await appServices.userDataStore.loadNotifiedEpisodeIds();
    final catalogueEpisodeIds = {
      for (final record in appServices.watchHistory)
        if (!record.isFilm && record.episodeId != null) record.episodeId!,
    };
    final eligible = alertsEligibleForSystemNotification(
      alerts: result.allAlerts,
      alreadyNotifiedEpisodeIds: alreadyNotified,
      catalogueEpisodeIds: catalogueEpisodeIds,
    );
    if (eligible.isEmpty) return;

    await NotificationService().showNewEpisodesNotification(
      count: eligible.length,
    );

    final updatedNotified = {
      ...alreadyNotified,
      for (final alert in eligible) alert.episodeId,
    };
    // Drop IDs that are no longer in the current alert snapshot.
    final activeIds = {for (final alert in result.allAlerts) alert.episodeId};
    updatedNotified.removeWhere((id) => !activeIds.contains(id));

    await appServices.userDataStore.saveNotifiedEpisodeIds(updatedNotified);
    await appServices.userDataStore.flush();
  }
}
