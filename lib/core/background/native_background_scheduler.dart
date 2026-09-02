import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';
import 'background_entrypoint.dart';
import 'background_task_constants.dart';

/// Registers native periodic episode checks on Android and iOS.
class NativeBackgroundScheduler {
  NativeBackgroundScheduler._();

  static final NativeBackgroundScheduler instance =
      NativeBackgroundScheduler._();

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!isSupported) return;
    await Workmanager().initialize(backgroundCallbackDispatcher);
  }

  Future<void> registerEpisodeChecks() async {
    if (!isSupported) return;

    await Workmanager().registerPeriodicTask(
      BackgroundTaskConstants.episodeCheckUniqueName,
      BackgroundTaskConstants.episodeCheckTaskName,
      frequency: const Duration(hours: AppConstants.notificationCheckIntervalHours),
      initialDelay: const Duration(hours: AppConstants.notificationCheckIntervalHours),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
