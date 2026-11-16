import '../../data/services/tmdb_service.dart';
import '../bootstrap/app_bootstrap.dart';
import '../notifications/notification_service.dart';

/// Initializes services for a background isolate.
class BackgroundBootstrap {
  /// Storage path, network and notifications only: [AppServices] is not
  /// started here because the UI isolate owns the user-data boxes.
  static Future<TmdbService> initialize() async {
    await AppBootstrap.initializePlatform();
    // No Activity in background: never prompt for permissions.
    await NotificationService().initialize(requestPermissions: false);
    return TmdbService();
  }
}
