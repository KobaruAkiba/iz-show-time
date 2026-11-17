import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';

enum LibrarySegment { watched, toWatch }

/// Full-width switch between the catalogue and the watchlist.
///
/// Each segment announces its title count to screen readers; the count is not
/// repeated visually to keep the labels short.
class LibrarySegmentSwitch extends StatelessWidget {
  final LibrarySegment selected;
  final ValueChanged<LibrarySegment> onChanged;
  final int watchedCount;
  final int toWatchCount;

  const LibrarySegmentSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.watchedCount,
    required this.toWatchCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SegmentedButton<LibrarySegment>(
      segments: [
        ButtonSegment(
          value: LibrarySegment.watched,
          label: _label(l10n, l10n.catalogueSegmentWatched, watchedCount),
        ),
        ButtonSegment(
          value: LibrarySegment.toWatch,
          label: _label(l10n, l10n.catalogueSegmentToWatch, toWatchCount),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      expandedInsets: EdgeInsets.zero,
    );
  }

  Widget _label(AppLocalizations l10n, String text, int count) {
    return Semantics(
      label: '$text, ${l10n.statsCatalogueTitleCount(count)}',
      excludeSemantics: true,
      child: Text(text),
    );
  }
}
