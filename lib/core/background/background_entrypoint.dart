import 'package:workmanager/workmanager.dart';

import '../background/background_bootstrap.dart';
import '../background/background_task_constants.dart';
import '../notifications/episode_check_service.dart';

/// Top-level entry point for Workmanager background isolates.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case BackgroundTaskConstants.episodeCheckTaskName:
        case BackgroundTaskConstants.episodeCheckUniqueName:
        case Workmanager.iOSBackgroundTask:
          final appServices = await BackgroundBootstrap.initializeAppServices();
          await EpisodeCheckService.runNativeBackgroundCheck(appServices);
          return true;
        default:
          return false;
      }
    } catch (error, stackTrace) {
      // ignore: avoid_print — background isolate; surfaces in logcat
      print('WorkManager episode check failed: $error\n$stackTrace');
      return false;
    }
  });
}
