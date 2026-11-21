import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/app_lifecycle_coordinator.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';

import '../support/fake_user_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleCoordinator', () {
    late AppLifecycleCoordinator coordinator;
    late int clearCount;

    setUp(() {
      final appServices = AppServices();
      appServices.userDataStore = FakeUserDataStore();
      clearCount = 0;
      coordinator = AppLifecycleCoordinator(
        appServices: appServices,
        clearNewEpisodesNotification: () async => clearCount++,
      );
    });

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
  });
}
