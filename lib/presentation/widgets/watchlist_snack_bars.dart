import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

/// Long enough to notice the message and reach the Undo action.
const Duration kWatchlistUndoDuration = Duration(seconds: 6);

/// Confirms a removal and offers to undo it; replaces any visible snackbar.
void showRemovedFromWatchlistSnackBar(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n, {
  required VoidCallback onUndo,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.removedFromWatchlist),
        duration: kWatchlistUndoDuration,
        action: SnackBarAction(label: l10n.undo, onPressed: onUndo),
      ),
    );
}

/// Plain confirmation for watchlist changes; replaces any visible snackbar.
void showWatchlistSnackBar(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
