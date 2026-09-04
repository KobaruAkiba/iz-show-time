import 'package:flutter/material.dart';
import '../../data/models/catalogue_item.dart';

enum MediaFilter { all, filmsOnly, tvOnly }

enum MediaSortOption {
  none,
  titleAsc,
  titleDesc,
  ratingAsc,
  ratingDesc,
}

String mediaFilterLabel(MediaFilter filter) {
  return switch (filter) {
    MediaFilter.all => 'All',
    MediaFilter.filmsOnly => 'Films',
    MediaFilter.tvOnly => 'TV',
  };
}

String mediaSortOptionLabel(MediaSortOption option) {
  return switch (option) {
    MediaSortOption.none => 'Default order',
    MediaSortOption.titleAsc => 'Title (A → Z)',
    MediaSortOption.titleDesc => 'Title (Z → A)',
    MediaSortOption.ratingDesc => 'Rating (high → low)',
    MediaSortOption.ratingAsc => 'Rating (low → high)',
  };
}

bool hasActiveMediaFilters({
  required MediaFilter mediaFilter,
  required MediaSortOption sortOption,
  bool inProgressOnly = false,
}) {
  return mediaFilter != MediaFilter.all ||
      sortOption != MediaSortOption.none ||
      inProgressOnly;
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
    return Badge(
      isLabelVisible: isActive,
      label: const Text(''),
      smallSize: 8,
      child: compact
          ? IconButton.outlined(
              onPressed: onPressed,
              icon: const Icon(Icons.tune),
              tooltip: 'Filters & sort',
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filters & sort'),
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
});

Future<MediaFiltersResult?> showMediaFiltersSheet(
  BuildContext context, {
  required MediaFilter mediaFilter,
  required MediaSortOption sortOption,
  bool inProgressOnly = false,
  bool showInProgressFilter = false,
}) {
  var draftMediaFilter = mediaFilter;
  var draftSortOption = sortOption;
  var draftInProgressOnly = inProgressOnly;

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
                  'Filters & sort',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Show',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<MediaFilter>(
                  segments: [
                    const ButtonSegment(
                      value: MediaFilter.all,
                      label: Text('All'),
                      icon: Icon(Icons.grid_view, size: 18),
                    ),
                    ButtonSegment(
                      value: MediaFilter.filmsOnly,
                      label: const Text('Films'),
                      icon: const Icon(Icons.movie_filter, size: 18),
                      enabled: !draftInProgressOnly,
                    ),
                    const ButtonSegment(
                      value: MediaFilter.tvOnly,
                      label: Text('TV'),
                      icon: Icon(Icons.tv_outlined, size: 18),
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
                if (showInProgressFilter) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  FilterChip(
                    label: const Text('In Progress'),
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
                  if (draftInProgressOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Shows with the next episode already aired and not yet registered.',
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
                  'Sort by',
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
                    title: Text(mediaSortOptionLabel(option)),
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
                        });
                      },
                      child: const Text('Reset'),
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
                          ),
                        );
                      },
                      child: const Text('Apply'),
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
