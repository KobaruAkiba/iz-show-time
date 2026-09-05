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
    final checker = NewEpisodeChecker(
      tmdbService: appServices.tmdbService,
      userDataStore: appServices.userDataStore,
    );

    return checker.checkShows(
      shows: appServices.followedTvShows,
      watchHistory: appServices.watchHistory,
      forceRefresh: true,
    );
  }

  /// Foreground refresh: updates in-memory alerts only, never notifies.
  static Future<void> refreshWhileAppOpen(AppServices appServices) async {
    final result = await checkCatalogue(appServices: appServices);
    appServices.updateNewEpisodeAlerts(result.allAlerts);
  }

  /// Native background task: persists alerts and notifies for episodes that
  /// aired today (local calendar day), at most once per episode.
  static Future<void> runNativeBackgroundCheck(AppServices appServices) async {
    final result = await checkCatalogue(appServices: appServices);
    appServices.updateNewEpisodeAlerts(result.allAlerts);

    final appIsOpen = await appServices.userDataStore.loadAppInForeground();
    if (appIsOpen) return;

    final alreadyNotified =
        await appServices.userDataStore.loadNotifiedEpisodeIds();
    final eligible = alertsEligibleForSystemNotification(
      alerts: result.allAlerts,
      alreadyNotifiedEpisodeIds: alreadyNotified,
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
