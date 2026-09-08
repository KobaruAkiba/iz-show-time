import 'package:flutter/material.dart';
import '../../core/utils/duration_format.dart';
import '../../l10n/l10n.dart';
import 'media_filters.dart';

/// Summary counts for films, shows, total catalogue items, and watch time.
///
/// Collapsed by default: only total watch time. Expanding reveals the three
/// type counters, which also act as the catalogue media-type filter.
class CatalogueStatsRow extends StatelessWidget {
  final int tvShowCount;
  final int filmCount;
  final int totalCount;
  final int watchTimeMinutes;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final MediaFilter selectedFilter;
  final ValueChanged<MediaFilter> onFilterSelected;

  const CatalogueStatsRow({
    super.key,
    required this.tvShowCount,
    required this.filmCount,
    required this.totalCount,
    this.watchTimeMinutes = 0,
    required this.expanded,
    required this.onToggleExpanded,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          _WatchTimeCard(
            minutes: watchTimeMinutes,
            expanded: expanded,
            onTap: onToggleExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: l10n.statsShows,
                            value: tvShowCount,
                            icon: Icons.tv,
                            selected: selectedFilter == MediaFilter.tvOnly,
                            onTap: () =>
                                onFilterSelected(MediaFilter.tvOnly),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: l10n.statsFilms,
                            value: filmCount,
                            icon: Icons.movie_filter,
                            selected: selectedFilter == MediaFilter.filmsOnly,
                            onTap: () =>
                                onFilterSelected(MediaFilter.filmsOnly),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: l10n.statsTotal,
                            value: totalCount,
                            icon: Icons.collections_bookmark,
                            selected: selectedFilter == MediaFilter.all,
                            onTap: () => onFilterSelected(MediaFilter.all),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WatchTimeCard extends StatelessWidget {
  final int minutes;
  final bool expanded;
  final VoidCallback onTap;

  const _WatchTimeCard({
    required this.minutes,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 24, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statsTotalWatchTime,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            formatDurationMinutes(minutes, l10n: l10n),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (isAtLeastOneDay(minutes)) ...[
                          const SizedBox(width: 8),
                          Text(
                            formatHoursOnlyHint(minutes, l10n: l10n),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 24,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
