import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/background/background_task_constants.dart';
import 'package:iz_show_time_tracker/core/background/background_task_dispatch.dart';
import 'package:iz_show_time_tracker/core/background/background_task_kind.dart';
import 'package:workmanager/workmanager.dart';

void main() {
  group('backgroundTaskKindFor', () {
    test('maps the periodic task names of Android and iOS', () {
      for (final name in [
        BackgroundTaskConstants.episodeCheckTaskName,
        BackgroundTaskConstants.episodeCheckUniqueName,
        Workmanager.iOSBackgroundTask,
      ]) {
        expect(backgroundTaskKindFor(name), BackgroundTaskKind.periodic);
      }
    });

    test('maps the iOS nightly processing task', () {
      expect(
        backgroundTaskKindFor(BackgroundTaskConstants.nightlyCheckUniqueName),
        BackgroundTaskKind.nightly,
      );
      expect(
        backgroundTaskKindFor(BackgroundTaskConstants.nightlyCheckTaskName),
        BackgroundTaskKind.nightly,
      );
    });

    test('ignores unknown tasks', () {
      expect(backgroundTaskKindFor('someOtherTask'), isNull);
    });
  });

  group('BackgroundTaskKind.fromStorageKey', () {
    test('round-trips every kind', () {
      for (final kind in BackgroundTaskKind.values) {
        expect(BackgroundTaskKind.fromStorageKey(kind.storageKey), kind);
      }
    });

    test('is null for missing or unknown values', () {
      expect(BackgroundTaskKind.fromStorageKey(null), isNull);
      expect(BackgroundTaskKind.fromStorageKey('weekly'), isNull);
      expect(BackgroundTaskKind.fromStorageKey(1), isNull);
    });
  });
}
