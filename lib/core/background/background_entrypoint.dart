import 'package:workmanager/workmanager.dart';

import 'background_bootstrap.dart';
import 'background_task_dispatch.dart';
import 'background_task_kind.dart';
import 'nightly_check_scheduler.dart';
import '../notifications/episode_check_service.dart';

/// Top-level entry point for Workmanager background isolates.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final taskKind = backgroundTaskKindFor(taskName);
    if (taskKind == null) return false;

    // Before the check: iOS may end the run at any time, and code after that
    // point would never run.
    if (taskKind == BackgroundTaskKind.nightly) {
      await NightlyCheckScheduler.schedule();
    }

    try {
      final tmdbService = await BackgroundBootstrap.initialize();
      await EpisodeCheckService.runNativeBackgroundCheck(
        tmdbService: tmdbService,
        taskKind: taskKind,
      );
      return true;
    } catch (error, stackTrace) {
      // ignore: avoid_print — background isolate; surfaces in logcat
      print('WorkManager episode check failed: $error\n$stackTrace');
      return false;
    }
  });
}
