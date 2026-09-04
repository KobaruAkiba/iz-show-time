import 'package:flutter/material.dart';
import '../../data/models/catalogue_item.dart';
import '../../l10n/l10n.dart';

/// Asks the user to confirm removing a film or TV show from the catalogue.
/// Returns `true` if the user confirms removal.
Future<bool> confirmRemoveFromCatalogue(
  BuildContext context,
  CatalogueItem item,
) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.bookmark_remove_outlined, color: Colors.red[700]),
      title: Text(l10n.confirmRemoveFromCatalogueTitle),
      content: Text(
        item.isFilm
            ? l10n.confirmRemoveFilmBody(item.title)
            : l10n.confirmRemoveShowBody(item.title),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.actionRemove),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
