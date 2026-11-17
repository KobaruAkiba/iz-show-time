import '../../../core/services/library_status.dart';
import '../../../l10n/l10n.dart';

/// Snackbar text for the Search bookmark; [statusBefore] is read before the
/// toggle, since a film leaving the watchlist reads differently.
String libraryToggleMessage(
  LibraryToggleResult result, {
  required LibraryStatus statusBefore,
  required AppLocalizations l10n,
}) =>
    switch (result) {
      LibraryToggleResult.addedToCatalogue =>
        statusBefore == LibraryStatus.watchlist
            ? l10n.movedToCatalogue
            : l10n.addedToCatalogue,
      LibraryToggleResult.removedFromCatalogue => l10n.removedFromCatalogue,
      LibraryToggleResult.addedToWatchlist => l10n.showAddedToWatchlist,
      LibraryToggleResult.alreadyOnWatchlist => l10n.alreadyOnWatchlist,
    };
