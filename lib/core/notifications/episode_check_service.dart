import '../services/app_services.dart';
import '../notifications/new_episode_checker.dart';
import '../notifications/notification_service.dart';

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
      shows: appServices.tvShows,
      watchHistory: appServices.watchHistory,
    );
  }

  /// Foreground refresh: updates in-memory alerts only, never notifies.
  static Future<void> refreshWhileAppOpen(AppServices appServices) async {
    final result = await checkCatalogue(appServices: appServices);
    appServices.updateNewEpisodeAlerts(result.allAlerts);
  }

  /// Native background task: persists alerts and notifies if the app is closed.
  static Future<void> runNativeBackgroundCheck(AppServices appServices) async {
    final result = await checkCatalogue(appServices: appServices);

    if (result.newlyDetected.isEmpty) return;

    final appIsOpen = await appServices.userDataStore.loadAppInForeground();
    if (appIsOpen) return;

    await NotificationService().showNewEpisodesNotification(
      count: result.newlyDetected.length,
    );
  }
}
