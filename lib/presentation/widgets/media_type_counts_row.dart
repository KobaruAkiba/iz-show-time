import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'media_filters.dart';

/// "All N / Shows N / Films N" chips that also act as the media-type filter.
///
/// Shared by the catalogue and the watchlist, so both filter by type the same
/// way. The total is the sum of the two counts.
class MediaTypeCountsRow extends StatelessWidget {
  final int tvShowCount;
  final int filmCount;
  final MediaFilter selectedFilter;
  final ValueChanged<MediaFilter> onFilterSelected;

  const MediaTypeCountsRow({
    super.key,
    required this.tvShowCount,
    required this.filmCount,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = filmCount + tvShowCount;

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _chip(MediaFilter.all, '${l10n.filterAll} $total'),
          _chip(MediaFilter.tvOnly, '${l10n.statsShows} $tvShowCount'),
          _chip(MediaFilter.filmsOnly, '${l10n.statsFilms} $filmCount'),
        ],
      ),
    );
  }

  Widget _chip(MediaFilter filter, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedFilter == filter,
      onSelected: (_) => onFilterSelected(filter),
    );
  }
}
