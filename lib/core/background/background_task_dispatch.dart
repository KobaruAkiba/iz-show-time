import 'package:workmanager/workmanager.dart';

import 'background_task_constants.dart';
import 'background_task_kind.dart';

/// Kind of episode check for a task name delivered by Workmanager, or null
/// when the task is not ours.
///
/// iOS delivers BGTaskScheduler tasks under their unique name, Android under
/// the task name, so both are accepted.
BackgroundTaskKind? backgroundTaskKindFor(String taskName) {
  return switch (taskName) {
    BackgroundTaskConstants.episodeCheckTaskName ||
    BackgroundTaskConstants.episodeCheckUniqueName ||
    Workmanager.iOSBackgroundTask =>
      BackgroundTaskKind.periodic,
    BackgroundTaskConstants.nightlyCheckTaskName ||
    BackgroundTaskConstants.nightlyCheckUniqueName =>
      BackgroundTaskKind.nightly,
    _ => null,
  };
}
