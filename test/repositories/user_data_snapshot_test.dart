import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/repositories/hive_user_data_store.dart';

void main() {
  group('UserDataSnapshot.isAppOpenAt', () {
    final now = DateTime(2026, 11, 21, 12);

    UserDataSnapshot snapshotWith({
      required bool appInForeground,
      DateTime? heartbeatAt,
    }) =>
        UserDataSnapshot(
          catalogue: const [],
          watchHistory: const [],
          newEpisodeAlerts: const [],
          appInForeground: appInForeground,
          notifiedEpisodeIds: const {},
          appForegroundHeartbeatAt: heartbeatAt,
        );

    test('is open with a recent heartbeat', () {
      final snapshot = snapshotWith(
        appInForeground: true,
        heartbeatAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(snapshot.isAppOpenAt(now), isTrue);
    });

    test('is closed with a stale heartbeat', () {
      final snapshot = snapshotWith(
        appInForeground: true,
        heartbeatAt: now.subtract(const Duration(minutes: 16)),
      );

      expect(snapshot.isAppOpenAt(now), isFalse);
    });

    test('is closed without a heartbeat', () {
      final snapshot = snapshotWith(appInForeground: true);

      expect(snapshot.isAppOpenAt(now), isFalse);
    });

    test('is closed when the flag is false', () {
      final snapshot = snapshotWith(
        appInForeground: false,
        heartbeatAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(snapshot.isAppOpenAt(now), isFalse);
    });
  });
}
