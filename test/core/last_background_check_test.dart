import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:iz_show_time_tracker/core/background/background_task_kind.dart';
import 'package:iz_show_time_tracker/core/background/last_background_check.dart';
import 'package:iz_show_time_tracker/data/repositories/background_check_outbox.dart';

void main() {
  group('LastBackgroundCheck.read', () {
    test('is never run when the outbox holds no result', () async {
      final lastCheck = await LastBackgroundCheck.read(
        readOutbox: () async => null,
      );

      expect(lastCheck, isA<LastBackgroundCheckNever>());
    });

    test('exposes the time and kind of the last run', () async {
      final checkedAt = DateTime.utc(2026, 11, 21, 3, 15);
      final lastCheck = await LastBackgroundCheck.read(
        readOutbox: () async => BackgroundCheckResult(
          alerts: const [],
          checkedAt: checkedAt,
          taskKind: BackgroundTaskKind.nightly,
        ),
      );

      expect(
        lastCheck,
        isA<LastBackgroundCheckAt>()
            .having((check) => check.checkedAt, 'checkedAt', checkedAt)
            .having(
              (check) => check.taskKind,
              'taskKind',
              BackgroundTaskKind.nightly,
            ),
      );
    });

    test('keeps the time when the kind is unknown', () async {
      final checkedAt = DateTime.utc(2026, 11, 20, 18);
      final lastCheck = await LastBackgroundCheck.read(
        readOutbox: () async =>
            BackgroundCheckResult(alerts: const [], checkedAt: checkedAt),
      );

      expect(
        lastCheck,
        isA<LastBackgroundCheckAt>()
            .having((check) => check.checkedAt, 'checkedAt', checkedAt)
            .having((check) => check.taskKind, 'taskKind', isNull),
      );
    });

    test('is unavailable when the outbox cannot be read', () async {
      final lastCheck = await LastBackgroundCheck.read(
        readOutbox: () async => throw HiveError('file is being written'),
      );

      expect(lastCheck, isA<LastBackgroundCheckUnavailable>());
    });
  });
}
