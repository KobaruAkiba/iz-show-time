import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/media_filters.dart';

/// "All N / Films N / Shows N" chips that also act as the media-type filter.
class WatchlistCountsRow extends StatelessWidget {
  final int filmCount;
  final int tvShowCount;
  final MediaFilter selectedFilter;
  final ValueChanged<MediaFilter> onFilterSelected;

  const WatchlistCountsRow({
    super.key,
    required this.filmCount,
    required this.tvShowCount,
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
          _chip(MediaFilter.filmsOnly, '${l10n.statsFilms} $filmCount'),
          _chip(MediaFilter.tvOnly, '${l10n.statsShows} $tvShowCount'),
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
