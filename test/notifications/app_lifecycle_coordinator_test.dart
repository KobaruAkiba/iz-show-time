import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/app_lifecycle_coordinator.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';

import '../support/fake_user_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleCoordinator', () {
    late AppLifecycleCoordinator coordinator;
    late FakeUserDataStore store;
    late int clearCount;

    setUp(() {
      final appServices = AppServices();
      store = FakeUserDataStore();
      appServices.userDataStore = store;
      clearCount = 0;
      coordinator = AppLifecycleCoordinator(
        appServices: appServices,
        clearNewEpisodesNotification: () async => clearCount++,
        heartbeatInterval: const Duration(minutes: 5),
      );
    });

    tearDown(() => coordinator.detach());

    test('clears the new episodes notification on resume', () {
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(clearCount, 1);
    });

    test('keeps the notification in other states', () {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        coordinator.didChangeAppLifecycleState(state);
      }

      expect(clearCount, 0);
    });

    testWidgets('refreshes the foreground heartbeat while resumed',
        (tester) async {
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(minutes: 5));

      expect(store.foregroundWrites, [true, true]);
      coordinator.detach();
    });

    testWidgets('does not start a second heartbeat on a repeated resume',
        (tester) async {
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(minutes: 5));

      expect(store.foregroundWrites, [true, true, true]);
      coordinator.detach();
    });

    testWidgets('stops the heartbeat when paused', (tester) async {
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 15));

      expect(store.foregroundWrites, [true, false]);
      coordinator.detach();
    });
  });
}
