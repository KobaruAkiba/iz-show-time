import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/screens/catalogue/catalogue_screen.dart';
import 'package:iz_show_time_tracker/presentation/screens/catalogue/library_segment_switch.dart';
import 'package:iz_show_time_tracker/presentation/widgets/catalogue_stats_row.dart';

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
    await tester.tap(find.text('Films 2'));
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

  testWidgets('type chips are always visible and filter the list',
      (tester) async {
    store.catalogue.add(const TvShow(id: 3, title: 'Gamma'));
    await pumpCatalogue(tester);
    expect(find.text('All 3'), findsOneWidget);
    expect(find.text('Shows 1'), findsOneWidget);
    expect(find.text('Films 2'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);

    await tester.tap(find.text('Shows 1'));
    await tester.pumpAndSettle();
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);

    await tester.tap(find.text('All 3'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
  });

  testWidgets('the summary line is thin and keeps the segment target tall',
      (tester) async {
    await pumpCatalogue(tester);
    expect(find.text('0m · 2 titles'), findsOneWidget);
    expect(tester.getSize(find.byType(CatalogueStatsRow)).height, 40);
    expect(
      tester.getSize(find.byType(SegmentedButton<LibrarySegment>)).height,
      greaterThanOrEqualTo(48),
    );
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
