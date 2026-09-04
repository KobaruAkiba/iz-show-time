import 'package:flutter/material.dart';
import '../../data/models/catalogue_item.dart';
import '../../l10n/l10n.dart';

enum MediaFilter { all, filmsOnly, tvOnly }

enum MediaSortOption {
  none,
  titleAsc,
  titleDesc,
  ratingAsc,
  ratingDesc,
}

String mediaFilterLabel(MediaFilter filter, AppLocalizations l10n) {
  return switch (filter) {
    MediaFilter.all => l10n.filterAll,
    MediaFilter.filmsOnly => l10n.filterFilms,
    MediaFilter.tvOnly => l10n.filterTv,
  };
}

String mediaSortOptionLabel(MediaSortOption option, AppLocalizations l10n) {
  return switch (option) {
    MediaSortOption.none => l10n.sortDefault,
    MediaSortOption.titleAsc => l10n.sortTitleAsc,
    MediaSortOption.titleDesc => l10n.sortTitleDesc,
    MediaSortOption.ratingDesc => l10n.sortRatingDesc,
    MediaSortOption.ratingAsc => l10n.sortRatingAsc,
  };
}

bool hasActiveMediaFilters({
  required MediaFilter mediaFilter,
  required MediaSortOption sortOption,
  bool inProgressOnly = false,
  bool favoritesOnly = false,
}) {
  return mediaFilter != MediaFilter.all ||
      sortOption != MediaSortOption.none ||
      inProgressOnly ||
      favoritesOnly;
}

List<CatalogueItem> applyMediaFilters(
  Iterable<CatalogueItem> items, {
  required MediaFilter mediaFilter,
  required MediaSortOption sortOption,
}) {
  final results = <CatalogueItem>[];
  switch (mediaFilter) {
    case MediaFilter.all:
      results.addAll(items);
    case MediaFilter.filmsOnly:
      results.addAll(items.where((item) => item.isFilm));
    case MediaFilter.tvOnly:
      results.addAll(items.where((item) => item.isTvShow));
  }

  switch (sortOption) {
    case MediaSortOption.none:
      break;
    case MediaSortOption.titleAsc:
      results.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    case MediaSortOption.titleDesc:
      results.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
    case MediaSortOption.ratingAsc:
      results.sort((a, b) => a.voteAverage.compareTo(b.voteAverage));
    case MediaSortOption.ratingDesc:
      results.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
  }

  return results;
}

/// Compact filters button with an active badge.
class MediaFiltersButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;
  final bool compact;

  const MediaFiltersButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Badge(
      isLabelVisible: isActive,
      label: const Text(''),
      smallSize: 8,
      child: compact
          ? IconButton.outlined(
              onPressed: onPressed,
              icon: const Icon(Icons.tune),
              tooltip: l10n.filtersAndSort,
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(l10n.filtersAndSort),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
    );
  }
}

typedef MediaFiltersResult = ({
  MediaFilter mediaFilter,
  MediaSortOption sortOption,
  bool inProgressOnly,
  bool favoritesOnly,
});

Future<MediaFiltersResult?> showMediaFiltersSheet(
  BuildContext context, {
  required MediaFilter mediaFilter,
  required MediaSortOption sortOption,
  bool inProgressOnly = false,
  bool favoritesOnly = false,
  bool showInProgressFilter = false,
  bool showFavoritesFilter = false,
}) {
  var draftMediaFilter = mediaFilter;
  var draftSortOption = sortOption;
  var draftInProgressOnly = inProgressOnly;
  var draftFavoritesOnly = favoritesOnly;
  final showStatusSection = showInProgressFilter || showFavoritesFilter;

  void applyInProgressConstraints() {
    if (!draftInProgressOnly) return;
    // In Progress is TV-only: films-only is incompatible.
    if (draftMediaFilter == MediaFilter.filmsOnly) {
      draftMediaFilter = MediaFilter.tvOnly;
    }
  }

  return showModalBottomSheet<MediaFiltersResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final l10n = context.l10n;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.filtersAndSort,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.filtersShowSection,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<MediaFilter>(
                  segments: [
                    ButtonSegment(
                      value: MediaFilter.all,
                      label: Text(l10n.filterAll),
                      icon: const Icon(Icons.grid_view, size: 18),
                    ),
                    ButtonSegment(
                      value: MediaFilter.filmsOnly,
                      label: Text(l10n.filterFilms),
                      icon: const Icon(Icons.movie_filter, size: 18),
                      enabled: !draftInProgressOnly,
                    ),
                    ButtonSegment(
                      value: MediaFilter.tvOnly,
                      label: Text(l10n.filterTv),
                      icon: const Icon(Icons.tv_outlined, size: 18),
                    ),
                  ],
                  selected: {draftMediaFilter},
                  onSelectionChanged: (selection) {
                    setSheetState(() {
                      draftMediaFilter = selection.first;
                      applyInProgressConstraints();
                    });
                  },
                ),
                if (showStatusSection) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.filtersStatusSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (showFavoritesFilter)
                        FilterChip(
                          label: Text(l10n.filtersFavorites),
                          selected: draftFavoritesOnly,
                          avatar: Icon(
                            draftFavoritesOnly
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                          ),
                          onSelected: (selected) {
                            setSheetState(() => draftFavoritesOnly = selected);
                          },
                        ),
                      if (showInProgressFilter)
                        FilterChip(
                          label: Text(l10n.filtersInProgress),
                          selected: draftInProgressOnly,
                          avatar: Icon(
                            draftInProgressOnly
                                ? Icons.play_circle_filled
                                : Icons.play_circle_outline,
                            size: 18,
                          ),
                          onSelected: (selected) {
                            setSheetState(() {
                              draftInProgressOnly = selected;
                              applyInProgressConstraints();
                            });
                          },
                        ),
                    ],
                  ),
                  if (draftInProgressOnly && showInProgressFilter)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.filtersInProgressHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                Text(
                  l10n.filtersSortBy,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                ...MediaSortOption.values.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      draftSortOption == option
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                    ),
                    title: Text(mediaSortOptionLabel(option, l10n)),
                    onTap: () =>
                        setSheetState(() => draftSortOption = option),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          draftMediaFilter = MediaFilter.all;
                          draftSortOption = MediaSortOption.none;
                          draftInProgressOnly = false;
                          draftFavoritesOnly = false;
                        });
                      },
                      child: Text(l10n.filtersReset),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        applyInProgressConstraints();
                        Navigator.pop(
                          context,
                          (
                            mediaFilter: draftMediaFilter,
                            sortOption: draftSortOption,
                            inProgressOnly: showInProgressFilter
                                ? draftInProgressOnly
                                : false,
                            favoritesOnly: showFavoritesFilter
                                ? draftFavoritesOnly
                                : false,
                          ),
                        );
                      },
                      child: Text(l10n.filtersApply),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
