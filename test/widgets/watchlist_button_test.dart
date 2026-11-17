import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/library_status.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/widgets/watchlist_button.dart';

Future<void> pump(
  WidgetTester tester,
  WatchlistButtonState state,
  VoidCallback onPressed,
) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WatchlistButton(state: state, onPressed: onPressed),
        ),
      ),
    );

void main() {
  test('maps library status to button state', () {
    expect(
      watchlistButtonStateFor(LibraryStatus.none),
      WatchlistButtonState.available,
    );
    expect(
      watchlistButtonStateFor(LibraryStatus.watchlist),
      WatchlistButtonState.onWatchlist,
    );
    expect(
      watchlistButtonStateFor(LibraryStatus.catalogue),
      WatchlistButtonState.inCatalogue,
    );
  });

  testWidgets('available adds, onWatchlist shows the checked icon',
      (tester) async {
    var taps = 0;
    await pump(tester, WatchlistButtonState.available, () => taps++);
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    await tester.tap(find.text('Add to Watchlist'));
    expect(taps, 1);
    await pump(tester, WatchlistButtonState.onWatchlist, () => taps++);
    expect(find.byIcon(Icons.playlist_add_check), findsOneWidget);
    expect(find.text('On Watchlist'), findsOneWidget);
    expect(
      tester.getSize(find.byType(WatchlistButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('inCatalogue is disabled and explains why', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pump(tester, WatchlistButtonState.inCatalogue, () => taps++);
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    await tester.tap(find.text('Add to Watchlist'), warnIfMissed: false);
    expect(taps, 0);
    expect(
      tester.getSemantics(find.byType(WatchlistButton)),
      isSemantics(
        label: 'Add to Watchlist',
        hint: 'Already in your catalogue',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });
}
