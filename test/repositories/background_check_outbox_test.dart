import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:iz_show_time_tracker/core/background/background_task_kind.dart';
import 'package:iz_show_time_tracker/data/repositories/background_check_outbox.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('background_check_outbox_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> save({BackgroundTaskKind? taskKind}) async {
    final outbox = await BackgroundCheckOutbox.openForWriting();
    await outbox.save(
      alerts: const [],
      checkedAt: DateTime(2026, 11, 21, 3),
      notifiedEpisodeIds: const {},
      taskKind: taskKind,
    );
    await outbox.close();
  }

  group('BackgroundCheckOutbox task kind', () {
    test('is stored with the result', () async {
      await save(taskKind: BackgroundTaskKind.nightly);

      final result = await BackgroundCheckOutbox.read();
      expect(result!.taskKind, BackgroundTaskKind.nightly);
    });

    test('is unknown for results saved without it', () async {
      await save();

      final result = await BackgroundCheckOutbox.read();
      expect(result!.checkedAt, DateTime(2026, 11, 21, 3));
      expect(result.taskKind, isNull);
    });

    test('is cleared when a later run does not report it', () async {
      await save(taskKind: BackgroundTaskKind.periodic);
      await save();

      expect((await BackgroundCheckOutbox.read())!.taskKind, isNull);
    });
  });
}
