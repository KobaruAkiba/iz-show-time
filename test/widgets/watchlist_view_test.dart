import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/screens/catalogue/watchlist_view.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_card.dart';

import '../support/fake_user_data_store.dart';

void main() {
  final appServices = AppServices();
  late FakeUserDataStore store;
  const dune = Film(id: 1, title: 'Dune');
  const severance = TvShow(id: 2, title: 'Severance');
  const arrival = Film(id: 3, title: 'Arrival');

  /// Seeds the store, initializes the services and pumps the view.
  Future<void> pumpView(
    WidgetTester tester, {
    List<WatchlistEntry> entries = const [],
    VoidCallback? onFind,
  }) async {
    store.watchlist.addAll(entries);
    await appServices.initialize(userDataStore: store);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: WatchlistView(onFindSomethingToWatch: onFind)),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() => store = FakeUserDataStore()..watchlistMigrationDone = true);

  final seeded = [
    WatchlistEntry(item: dune, addedAt: DateTime(2026, 1, 1)),
    WatchlistEntry(item: severance, addedAt: DateTime(2026, 3, 1)),
    WatchlistEntry(item: arrival, addedAt: DateTime(2026, 2, 1)),
  ];

  testWidgets('lists the most recently added first', (tester) async {
    await pumpView(tester, entries: seeded);
    final dy = [
      for (final t in ['Severance', 'Arrival', 'Dune'])
        tester.getTopLeft(find.text(t)).dy,
    ];
    expect(dy[0] < dy[1] && dy[1] < dy[2], isTrue);
  });

  testWidgets('counts row filters by type', (tester) async {
    await pumpView(tester, entries: seeded);
    expect(find.text('All 3'), findsOneWidget);
    expect(find.text('Films 2'), findsOneWidget);
    expect(find.text('Shows 1'), findsOneWidget);
    await tester.tap(find.text('Films 2'));
    await tester.pumpAndSettle();
    expect(find.text('Severance'), findsNothing);
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('search filters and shows a no-match state', (tester) async {
    await pumpView(tester, entries: seeded);
    expect(
      find.widgetWithText(TextField, 'Search watchlist...'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'dun');
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Arrival'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No titles match your filters'), findsOneWidget);
  });

  testWidgets('empty state calls back to Search', (tester) async {
    var called = false;
    await pumpView(tester, onFind: () => called = true);
    expect(find.text('Your watchlist is empty'), findsOneWidget);
    expect(
      find.text('Save films and shows you want to watch from their details.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    await tester.tap(find.text('Find something to watch'));
    expect(called, isTrue);
  });

  testWidgets('removing offers a 6 s Undo that restores the original date',
      (tester) async {
    await pumpView(tester, entries: seeded);
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('Dune'), matching: find.byType(MediaCard)),
      matching: find.byTooltip('Remove from watchlist'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsNothing);
    expect(find.text('Removed from watchlist'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(seconds: 6),
    );
    expect(find.byIcon(Icons.favorite_border), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(appServices.watchlist.addedAtByMediaKey['m_1'], DateTime(2026, 1, 1));
  });
}
