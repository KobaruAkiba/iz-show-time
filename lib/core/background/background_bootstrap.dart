import '../bootstrap/app_bootstrap.dart';
import '../notifications/notification_service.dart';
import '../services/app_services.dart';

/// Initializes services for a background isolate.
class BackgroundBootstrap {
  static Future<AppServices> initializeAppServices() async {
    final appServices = await AppBootstrap.initializeServices();
    await NotificationService().initialize();
    return appServices;
  }
}
