import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/active_media_filter_chips.dart';
import '../../widgets/floating_search_header.dart';
import '../../widgets/lazy_paged_list_view.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/media_filters.dart';
import '../../widgets/media_search_field.dart';
import '../../widgets/media_type_counts_row.dart';
import '../../widgets/watchlist_snack_bars.dart';
import '../../../core/services/app_services.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../data/models/watchlist_entry.dart';
import '../../../l10n/l10n.dart';

/// Body of the "To watch" segment: type counts that scroll away, a floating
/// search with the sort chip, and the saved titles.
class WatchlistView extends StatefulWidget {
  final VoidCallback? onFindSomethingToWatch;

  const WatchlistView({super.key, this.onFindSomethingToWatch});

  @override
  State<WatchlistView> createState() => _WatchlistViewState();
}

class _WatchlistViewState extends State<WatchlistView> {
  String _searchQuery = '';
  MediaFilter _mediaFilter = MediaFilter.all;
  MediaSortOption _sortOption = MediaSortOption.none;
  final _watchlist = AppServices().watchlist;

  List<CatalogueItem> _filterItems(List<WatchlistEntry> entries) {
    Iterable<CatalogueItem> items = entries.map((entry) => entry.item);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) => item.title.toLowerCase().contains(query));
    }
    return applyMediaFilters(
      items,
      mediaFilter: _mediaFilter,
      sortOption: _sortOption,
      recencyByMediaKey: _watchlist.addedAtByMediaKey,
    );
  }

  Future<void> _showFiltersSheet() async {
    // Type comes from the counts row, so the sheet only offers sorting.
    final result = await showMediaFiltersSheet(
      context,
      mediaFilter: _mediaFilter,
      sortOption: _sortOption,
      showMediaTypeFilter: false,
    );
    if (result == null || !mounted) return;
    setState(() => _sortOption = result.sortOption);
  }

  void _openDetails(CatalogueItem item) {
    showMediaDetailSheet(context, item);
  }

  Future<void> _remove(CatalogueItem item) async {
    // Capture everything needed after the await.
    final entry = _watchlist.entryFor(item);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final removed = await _watchlist.remove(item);
    if (!removed || entry == null) return;
    showRemovedFromWatchlistSnackBar(
      messenger,
      l10n,
      // restore() handles its own persistence errors.
      onUndo: () => unawaited(_watchlist.restore(entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WatchlistEntry>>(
      valueListenable: _watchlist.listenable,
      builder: (context, entries, _) {
        if (entries.isEmpty) return _buildEmptyState(context);
        return _buildContent(context, entries);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<WatchlistEntry> entries) {
    final l10n = context.l10n;
    final filmCount = entries.where((entry) => entry.item.isFilm).length;
    final items = _filterItems(entries);

    return _buildItemList(
      context,
      items,
      headerSlivers: [
        // Scrolls away with the list.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: MediaTypeCountsRow(
              filmCount: filmCount,
              tvShowCount: entries.length - filmCount,
              selectedFilter: _mediaFilter,
              onFilterSelected: (filter) =>
                  setState(() => _mediaFilter = filter),
            ),
          ),
        ),
        FloatingSearchHeader(
          search: MediaSearchField(
            hintText: l10n.watchlistSearchHint,
            onChanged: (value) => setState(() => _searchQuery = value),
            filtersActive: _sortOption != MediaSortOption.none,
            onFiltersPressed: _showFiltersSheet,
          ),
          // The type is already shown by the counts row; only sort is a chip.
          chips: _sortOption == MediaSortOption.none
              ? null
              : ActiveMediaFilterChips(
                  sortOption: _sortOption,
                  onClearSort: () =>
                      setState(() => _sortOption = MediaSortOption.none),
                ),
        ),
      ],
    );
  }

  Widget _buildItemList(
    BuildContext context,
    List<CatalogueItem> items, {
    required List<Widget> headerSlivers,
  }) {
    final l10n = context.l10n;

    return LazyPagedListView(
      headerSlivers: headerSlivers,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      emptyChild: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.watchlistNoFilterMatches,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      // Local data only: the window resets when the query or order changes.
      resetKey: Object.hash(_searchQuery, _mediaFilter, _sortOption),
      totalItemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MediaCard(
            item: item,
            onTap: () => _openDetails(item),
            trailingAction: IconButton(
              icon: const Icon(Icons.playlist_add_check, size: 24),
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              tooltip: l10n.removeFromWatchlist,
              onPressed: () => unawaited(_remove(item)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.watchlistEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.watchlistEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: widget.onFindSomethingToWatch,
              child: Text(l10n.watchlistEmptyCta),
            ),
          ],
        ),
      ),
    );
  }
}
