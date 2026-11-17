import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/screens/catalogue/catalogue_screen.dart';

import '../support/fake_user_data_store.dart';

void main() {
  final appServices = AppServices();
  late FakeUserDataStore store;

  Future<void> pumpCatalogue(
    WidgetTester tester, {
    VoidCallback? onFindSomethingToWatch,
  }) async {
    await appServices.initialize(userDataStore: store);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CatalogueScreen(onFindSomethingToWatch: onFindSomethingToWatch),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    store = FakeUserDataStore()
      ..watchlistMigrationDone = true
      ..catalogue.addAll(const [
        Film(id: 1, title: 'Alpha'),
        Film(id: 2, title: 'Beta'),
      ]);
  });

  testWidgets('search narrows the catalogue by title', (tester) async {
    await pumpCatalogue(tester);
    await tester.enterText(find.byType(TextField), 'alp');
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
  });

  testWidgets('the type filter shows a chip that clears it', (tester) async {
    await pumpCatalogue(tester);
    await tester.tap(find.text('Total Watch Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Films').first);
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byType(InputChip),
            matching: find.byType(Icon),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('an empty catalogue shows the empty message', (tester) async {
    store.catalogue.clear();
    await pumpCatalogue(tester);
    expect(find.text('Your catalogue is empty'), findsOneWidget);
  });

  testWidgets('switches segments and keeps each segment search',
      (tester) async {
    store.watchlist.add(WatchlistEntry(
      item: const Film(id: 9, title: 'Gamma'),
      addedAt: DateTime(2026, 1, 1),
    ));
    await pumpCatalogue(tester);
    expect(find.text('Alpha'), findsOneWidget);

    await tester.tap(find.text('To watch'));
    await tester.pumpAndSettle();
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    await tester.enterText(find.byType(TextField).hitTestable(), 'zzz');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Watched'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('segments announce their title count', (tester) async {
    final handle = tester.ensureSemantics();
    store.watchlist.add(WatchlistEntry(
      item: const Film(id: 9, title: 'Gamma'),
      addedAt: DateTime(2026, 1, 1),
    ));
    await pumpCatalogue(tester);
    expect(find.bySemanticsLabel('Watched, 2 titles'), findsOneWidget);
    expect(find.bySemanticsLabel('To watch, 1 title'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the empty watchlist CTA reaches the navigator callback',
      (tester) async {
    var called = false;
    await pumpCatalogue(tester, onFindSomethingToWatch: () => called = true);
    await tester.tap(find.text('To watch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find something to watch'));
    expect(called, isTrue);
  });
}
