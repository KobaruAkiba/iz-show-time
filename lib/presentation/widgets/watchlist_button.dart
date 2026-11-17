import 'package:flutter/material.dart';

import '../../core/services/library_status.dart';
import '../../l10n/l10n.dart';

/// What the detail sheet's watchlist button offers for a title.
enum WatchlistButtonState { available, onWatchlist, inCatalogue }

WatchlistButtonState watchlistButtonStateFor(LibraryStatus status) =>
    switch (status) {
      LibraryStatus.none => WatchlistButtonState.available,
      LibraryStatus.watchlist => WatchlistButtonState.onWatchlist,
      LibraryStatus.catalogue => WatchlistButtonState.inCatalogue,
    };

/// Full-width outlined button that adds to or removes from the watchlist.
///
/// In [WatchlistButtonState.inCatalogue] it is always disabled, whatever
/// [onPressed] is, and its semantics hint says why.
class WatchlistButton extends StatelessWidget {
  const WatchlistButton({super.key, required this.state, this.onPressed});

  final WatchlistButtonState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onWatchlist = state == WatchlistButtonState.onWatchlist;
    final inCatalogue = state == WatchlistButtonState.inCatalogue;

    final button = SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: inCatalogue ? null : onPressed,
        icon: Icon(onWatchlist ? Icons.playlist_add_check : Icons.playlist_add),
        label: Text(onWatchlist ? l10n.onWatchlist : l10n.addToWatchlist),
      ),
    );
    if (!inCatalogue) return button;

    // One node, so the hint and the disabled state are read together.
    return MergeSemantics(
      child: Semantics(hint: l10n.alreadyInCatalogueHint, child: button),
    );
  }
}
