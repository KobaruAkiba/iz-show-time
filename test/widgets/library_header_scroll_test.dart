import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/screens/catalogue/catalogue_screen.dart';
import 'package:iz_show_time_tracker/presentation/screens/catalogue/library_segment_switch.dart';
import 'package:iz_show_time_tracker/presentation/widgets/catalogue_stats_row.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_search_field.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_type_counts_row.dart';

import '../support/fake_user_data_store.dart';

/// The library header: the summary scrolls away, the search floats back.
void main() {
  final appServices = AppServices();
  late FakeUserDataStore store;

  String title(int n) => 'Film ${n.toString().padLeft(3, '0')}';

  Future<void> pumpLibrary(WidgetTester tester) async {
    await appServices.initialize(userDataStore: store);
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CatalogueScreen(),
    ));
    await tester.pumpAndSettle();
  }

  final catalogueScroll = find.byType(CustomScrollView);
  final segmentSwitch = find.byType(SegmentedButton<LibrarySegment>);
  final statsRow = find.byType(CatalogueStatsRow).hitTestable();
  final typeChips = find.byType(MediaTypeCountsRow).hitTestable();
  final searchField = find.byType(MediaSearchField).hitTestable();

  Future<void> scrollDown(WidgetTester tester, double dy) async {
    await tester.drag(catalogueScroll, Offset(0, -dy));
    await tester.pumpAndSettle();
  }

  Future<void> scrollUp(WidgetTester tester, double dy) async {
    await tester.drag(catalogueScroll, Offset(0, dy));
    await tester.pumpAndSettle();
  }

  setUp(() {
    store = FakeUserDataStore()
      ..watchlistMigrationDone = true
      ..catalogue.addAll([
        for (var i = 1; i <= 100; i++) Film(id: i, title: title(i)),
      ]);
  });

  testWidgets('at rest the header shows stats, type chips and search',
      (tester) async {
    await pumpLibrary(tester);
    expect(statsRow, findsOneWidget);
    expect(typeChips, findsOneWidget);
    expect(searchField, findsOneWidget);
  });

  testWidgets(
      'scrolling down hides summary, type chips and search but keeps '
      'the segment switch', (tester) async {
    await pumpLibrary(tester);
    await scrollDown(tester, 900);
    expect(statsRow, findsNothing);
    expect(typeChips, findsNothing);
    expect(searchField, findsNothing);
    expect(segmentSwitch.hitTestable(), findsOneWidget);
  });

  testWidgets(
      'scrolling up mid-list brings the search and type chips back, not the summary',
      (tester) async {
    await pumpLibrary(tester);
    await scrollDown(tester, 1500);
    expect(searchField, findsNothing);

    await scrollUp(tester, 150);
    expect(searchField, findsOneWidget);
    expect(statsRow, findsNothing);
    expect(typeChips, findsOneWidget);
    expect(segmentSwitch.hitTestable(), findsOneWidget);
  });

  testWidgets('the search keeps its text while it is scrolled away',
      (tester) async {
    await pumpLibrary(tester);
    await tester.enterText(find.byType(TextField), 'film');
    await tester.pumpAndSettle();
    await scrollDown(tester, 900);
    expect(searchField, findsNothing);
    await scrollUp(tester, 150);
    expect(find.text('film'), findsOneWidget);
  });

  testWidgets(
      'no results keeps search and type chips on screen with the '
      'message inside the scroll', (tester) async {
    await pumpLibrary(tester);
    await scrollDown(tester, 1500);
    await scrollUp(tester, 150);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No results match your filters'), findsOneWidget);
    expect(searchField, findsOneWidget);
    expect(typeChips, findsOneWidget);
    expect(
      find.descendant(
        of: catalogueScroll,
        matching: find.text('No results match your filters'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a type filter without matches keeps the header usable',
      (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.text('Shows 0'));
    await tester.pumpAndSettle();
    expect(find.text('No results match your filters'), findsOneWidget);
    expect(searchField, findsOneWidget);
    expect(find.text('Films 100'), findsOneWidget);
    // The selected type chip is the only indicator: no duplicate chip.
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('lazy pagination still reveals every item while scrolling',
      (tester) async {
    await pumpLibrary(tester);
    expect(find.text(title(100), skipOffstage: false), findsNothing);
    await tester.scrollUntilVisible(
      find.text(title(100)),
      500,
      scrollable: find
          .descendant(of: catalogueScroll, matching: find.byType(Scrollable))
          .first,
      maxScrolls: 200,
    );
    expect(find.text(title(100)), findsOneWidget);
  });

  testWidgets('the search stays visible while typing with the keyboard up',
      (tester) async {
    addTearDown(tester.view.reset);
    await pumpLibrary(tester);
    await scrollDown(tester, 1500);
    await scrollUp(tester, 150);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'film 05');
    await tester.pumpAndSettle();
    expect(searchField, findsOneWidget);
    expect(find.text('film 05'), findsOneWidget);
  });

  testWidgets(
      'a short list that barely overflows still snaps the header '
      'fully shown or fully hidden', (tester) async {
    // Phone-like screen where five titles overflow the viewport only a little.
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2260);
    addTearDown(tester.view.reset);
    store.catalogue
      ..clear()
      ..addAll([for (var i = 1; i <= 5; i++) Film(id: i, title: title(i))]);
    await pumpLibrary(tester);

    /// Visible height of the floating header, read from its render sliver.
    double headerPaintExtent() {
      final field = find.byType(MediaSearchField, skipOffstage: false);
      if (field.evaluate().isEmpty) return 0;
      RenderObject node = tester.renderObject(field);
      while (node is! RenderSliver) {
        node = node.parent!;
      }
      return node.geometry!.paintExtent;
    }

    // Scroll to the bottom, then reveal the header with a slow partial drag.
    await tester.timedDrag(catalogueScroll, const Offset(0, -900),
        const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(headerPaintExtent(), 0);
    expect(searchField, findsNothing);

    await tester.timedDrag(catalogueScroll, const Offset(0, 50),
        const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    final shown = headerPaintExtent();
    expect(shown, greaterThan(0));
    expect(searchField, findsOneWidget);
    expect(
        shown,
        tester.getSize(find.byType(MediaSearchField)).height +
            tester.getSize(find.byType(MediaTypeCountsRow)).height +
            8 +
            16);

    // A drag down hides it again, and it does not stay half hidden.
    await tester.timedDrag(catalogueScroll, const Offset(0, -50),
        const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(headerPaintExtent(), 0);
  });

  testWidgets('the watchlist header floats the same way', (tester) async {
    store.watchlist.addAll([
      for (var i = 1; i <= 60; i++)
        WatchlistEntry(
          item: Film(id: 1000 + i, title: 'Wish $i'),
          addedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
        ),
    ]);
    await pumpLibrary(tester);
    await tester.tap(find.text('To watch'));
    await tester.pumpAndSettle();
    expect(searchField, findsOneWidget);
    expect(typeChips, findsOneWidget);

    await scrollDown(tester, 1500);
    expect(searchField, findsNothing);
    expect(typeChips, findsNothing);
    expect(segmentSwitch.hitTestable(), findsOneWidget);

    await scrollUp(tester, 150);
    expect(searchField, findsOneWidget);
    expect(typeChips, findsOneWidget);
  });

  testWidgets('each segment keeps its own scroll position', (tester) async {
    store.watchlist.add(WatchlistEntry(
      item: const Film(id: 1001, title: 'Wish'),
      addedAt: DateTime(2026, 1, 1),
    ));
    await pumpLibrary(tester);
    await scrollDown(tester, 1500);
    expect(searchField, findsNothing);

    await tester.tap(find.text('To watch'));
    await tester.pumpAndSettle();
    expect(searchField, findsOneWidget);

    await tester.tap(find.text('Watched'));
    await tester.pumpAndSettle();
    expect(searchField, findsNothing);
    expect(typeChips, findsNothing);
  });
}
