import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/navigation/main_navigator.dart';
import 'package:iz_show_time_tracker/presentation/navigation/main_tab.dart';

import '../support/fake_user_data_store.dart';

/// The Settings tab reads the notification permission on mount; tests have
/// no registered plugin platform, so a fake answers instead.
class _FakeAndroidNotificationsPlugin
    extends AndroidFlutterLocalNotificationsPlugin {
  @override
  Future<bool?> areNotificationsEnabled() async => false;
}

void main() {
  final appServices = AppServices();
  late MainTabRequests requests;

  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance =
        _FakeAndroidNotificationsPlugin();
  });

  Future<void> pumpNavigator(WidgetTester tester) async {
    await appServices.initialize(
      userDataStore: FakeUserDataStore()..watchlistMigrationDone = true,
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainNavigator(tabRequests: requests),
      ),
    );
    await tester.pumpAndSettle();
  }

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.settings_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(selectedIndex(tester), MainTab.settings.index);
  }

  setUp(() => requests = MainTabRequests());

  testWidgets('shows Home when a tab request arrives', (tester) async {
    await pumpNavigator(tester);
    await openSettings(tester);

    requests.show(MainTab.home);
    await tester.pumpAndSettle();

    expect(selectedIndex(tester), MainTab.home.index);
  });

  testWidgets('closes an open sheet before showing Home', (tester) async {
    await pumpNavigator(tester);
    await openSettings(tester);
    unawaited(
      showModalBottomSheet<void>(
        context: tester.element(find.byType(NavigationBar)),
        builder: (_) => const Text('sheet'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);

    requests.show(MainTab.home);
    await tester.pumpAndSettle();

    expect(find.text('sheet'), findsNothing);
    expect(selectedIndex(tester), MainTab.home.index);
  });

  testWidgets('handles a request made before it was built', (tester) async {
    requests.show(MainTab.home);

    await pumpNavigator(tester);

    expect(requests.take(), isNull);
    expect(selectedIndex(tester), MainTab.home.index);
  });
}
