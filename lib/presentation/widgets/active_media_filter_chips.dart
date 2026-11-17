import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'media_filters.dart';

/// Wrap of dismissible chips: [extraChips], then sort.
///
/// The media type is not listed: the type counts row already shows it.
class ActiveMediaFilterChips extends StatelessWidget {
  final MediaSortOption sortOption;
  final VoidCallback onClearSort;
  final List<Widget> extraChips;

  const ActiveMediaFilterChips({
    super.key,
    required this.sortOption,
    required this.onClearSort,
    this.extraChips = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...extraChips,
          if (sortOption != MediaSortOption.none)
            InputChip(
              label: Text(mediaSortOptionLabel(sortOption, l10n)),
              onDeleted: onClearSort,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
