import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/library_status.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/screens/search/library_toggle_message.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('maps each toggle outcome to its snackbar text', () {
    String msg(
      LibraryToggleResult result, [
      LibraryStatus before = LibraryStatus.none,
    ]) =>
        libraryToggleMessage(result, statusBefore: before, l10n: l10n);

    expect(msg(LibraryToggleResult.addedToCatalogue), 'Added to catalogue');
    expect(
      msg(LibraryToggleResult.addedToCatalogue, LibraryStatus.watchlist),
      'Moved from watchlist to your catalogue',
    );
    expect(
      msg(LibraryToggleResult.removedFromCatalogue, LibraryStatus.catalogue),
      'Removed from catalogue',
    );
    expect(
      msg(LibraryToggleResult.addedToWatchlist),
      'Added to your watchlist. Mark an episode as watched to add it to your catalogue.',
    );
    expect(
      msg(LibraryToggleResult.alreadyOnWatchlist, LibraryStatus.watchlist),
      'Already on your watchlist',
    );
  });
}
