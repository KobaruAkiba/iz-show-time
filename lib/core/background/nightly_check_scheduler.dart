import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'background_task_constants.dart';

/// Schedules the iOS nightly episode check (BGProcessingTask).
///
/// Processing tasks are one-shot and the plugin does not resubmit them, so
/// every app launch and every nightly run schedules the next one. Submitting
/// again replaces the pending request. Safe from the background isolate: the
/// plugin reads the callback handle stored by the app's `initialize`.
abstract final class NightlyCheckScheduler {
  static bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Failures are logged, never thrown: the periodic check still runs.
  static Future<void> schedule() async {
    if (!isSupported) return;
    try {
      await Workmanager().registerProcessingTask(
        BackgroundTaskConstants.nightlyCheckUniqueName,
        BackgroundTaskConstants.nightlyCheckTaskName,
        initialDelay: BackgroundTaskConstants.nightlyCheckInitialDelay,
        // No external power requirement: iOS already picks idle moments for
        // processing tasks, and requiring a charger would cut the chances
        // further for a short, network-bound check.
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresCharging: false,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Nightly check scheduling failed: $error\n$stackTrace');
    }
  }
}
