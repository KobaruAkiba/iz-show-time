import 'package:flutter/material.dart';
import '../../data/models/catalogue_item.dart';

/// Asks the user to confirm removing a film or TV show from the catalogue.
/// Returns `true` if the user confirms removal.
Future<bool> confirmRemoveFromCatalogue(
  BuildContext context,
  CatalogueItem item,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.bookmark_remove_outlined, color: Colors.red[700]),
      title: const Text('Remove from Catalogue'),
      content: Text(
        item.isFilm
            ? 'Remove the film "${item.title}" from your catalogue?\n\n'
                'Watch history for this title will be permanently deleted.'
            : 'Remove the show "${item.title}" from your catalogue?\n\n'
                'All watched episodes will be permanently deleted from your '
                'watch history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
