import 'package:flutter/material.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_filters.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/catalogue_stats_row.dart';
import '../../widgets/confirm_remove_from_catalogue.dart';
import '../../widgets/lazy_paged_list_view.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/notifications/show_in_progress.dart';
import '../../../core/services/app_services.dart';
import '../../../core/utils/catalogue_activity.dart';
import '../../../l10n/l10n.dart';

/// Screen displaying the user's catalogue of films and shows
class CatalogueScreen extends StatefulWidget {
  final bool isActive;

  const CatalogueScreen({super.key, this.isActive = true});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  String _searchQuery = '';
  MediaFilter _mediaFilter = MediaFilter.all;
  MediaSortOption _sortOption = MediaSortOption.none;
  bool _inProgressOnly = false;
  bool _favoritesOnly = false;
  bool _notFollowedOnly = false;
  bool _statsExpanded = false;
  final _appServices = AppServices();

  bool get _forcesTvOnly => _inProgressOnly || _notFollowedOnly;

  /// Chips row: type + sheet filters (status / sort).
  bool get _hasActiveFilters => hasActiveMediaFilters(
        mediaFilter: _mediaFilter,
        sortOption: _sortOption,
        inProgressOnly: _inProgressOnly,
        favoritesOnly: _favoritesOnly,
        notFollowedOnly: _notFollowedOnly,
      );

  /// Tune button badge: only filters controlled by the sheet (not media type).
  bool get _hasActiveSheetFilters =>
      _sortOption != MediaSortOption.none ||
      _inProgressOnly ||
      _favoritesOnly ||
      _notFollowedOnly;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onBecameActive());
    }
  }

  @override
  void didUpdateWidget(covariant CatalogueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _onBecameActive();
    }
  }

  Future<void> _onBecameActive() async {
    _refresh();
    await _appServices.syncTvShowAiringStates();
    if (mounted) _refresh();
  }

  List<CatalogueItem> _filterItems(List<CatalogueItem> items) {
    Iterable<CatalogueItem> filtered = items;

    if (_favoritesOnly) {
      filtered = filtered.where((item) => item.isFavorite);
    }

    if (_inProgressOnly) {
      filtered = filtered.where(
        (item) => item is TvShow && isShowInProgress(item),
      );
    }

    if (_notFollowedOnly) {
      filtered = filtered.where(
        (item) => item is TvShow && !item.isFollowed,
      );
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((item) => item.title.toLowerCase().contains(query));
    }

    // In Progress / Not Followed imply TV-only even when media filter is "All".
    final effectiveMediaFilter =
        _forcesTvOnly && _mediaFilter == MediaFilter.all
            ? MediaFilter.tvOnly
            : _mediaFilter;

    return applyMediaFilters(
      filtered,
      mediaFilter: effectiveMediaFilter,
      sortOption: _sortOption,
      lastCatalogueActivityByMediaId: lastCatalogueActivityByMediaId(
        _appServices.watchHistory,
      ),
    );
  }

  void _refresh() => setState(() {});

  Future<void> _showFiltersSheet() async {
    final result = await showMediaFiltersSheet(
      context,
      mediaFilter: _mediaFilter,
      sortOption: _sortOption,
      inProgressOnly: _inProgressOnly,
      favoritesOnly: _favoritesOnly,
      notFollowedOnly: _notFollowedOnly,
      showInProgressFilter: true,
      showFavoritesFilter: true,
      showNotFollowedFilter: true,
      showMediaTypeFilter: false,
    );
    if (result == null || !mounted) return;
    setState(() {
      _sortOption = result.sortOption;
      _inProgressOnly = result.inProgressOnly;
      _favoritesOnly = result.favoritesOnly;
      _notFollowedOnly = result.notFollowedOnly;
      // Sheet no longer owns media type; keep counters in sync with TV-only filters.
      if ((result.inProgressOnly || result.notFollowedOnly) &&
          _mediaFilter == MediaFilter.filmsOnly) {
        _mediaFilter = MediaFilter.tvOnly;
      } else {
        _mediaFilter = result.mediaFilter;
      }
    });
  }

  void _onMediaFilterSelected(MediaFilter filter) {
    setState(() {
      _mediaFilter = filter;
      // Films + TV-only status filters are incompatible; Films tap clears them.
      if (filter == MediaFilter.filmsOnly) {
        if (_inProgressOnly) _inProgressOnly = false;
        if (_notFollowedOnly) _notFollowedOnly = false;
      }
    });
  }

  void _clearMediaFilter() {
    setState(() => _mediaFilter = MediaFilter.all);
  }

  void _clearInProgress() {
    setState(() => _inProgressOnly = false);
  }

  void _clearFavorites() {
    setState(() => _favoritesOnly = false);
  }

  void _clearNotFollowed() {
    setState(() => _notFollowedOnly = false);
  }

  void _clearSort() {
    setState(() => _sortOption = MediaSortOption.none);
  }

  void _openDetails(CatalogueItem item) {
    showMediaDetailSheet(
      context,
      item,
      onWatchTimeChanged: _refresh,
    );
  }

  Future<void> _toggleFavorite(CatalogueItem item) async {
    await _appServices.toggleFavorite(item.id);
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final films = _appServices.films;
    final tvShows = _appServices.tvShows;
    final catalogue = _appServices.catalogue;
    final watchTime = _appServices.totalWatchTimeMinutes;
    final items = _filterItems(catalogue);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(),
            CatalogueStatsRow(
              tvShowCount: tvShows.length,
              filmCount: films.length,
              totalCount: catalogue.length,
              watchTimeMinutes: watchTime,
              expanded: _statsExpanded,
              onToggleExpanded: () =>
                  setState(() => _statsExpanded = !_statsExpanded),
              selectedFilter: _mediaFilter,
              onFilterSelected: _onMediaFilterSelected,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: l10n.catalogueSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MediaFiltersButton(
                    isActive: _hasActiveSheetFilters,
                    onPressed: _showFiltersSheet,
                    compact: true,
                  ),
                ],
              ),
            ),
            if (_hasActiveFilters) _buildActiveFilterChips(),
            const SizedBox(height: 12),
            Expanded(child: _buildItemList(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (_mediaFilter != MediaFilter.all)
              InputChip(
                label: Text(mediaFilterLabel(_mediaFilter, l10n)),
                onDeleted: _clearMediaFilter,
                visualDensity: VisualDensity.compact,
              ),
            if (_favoritesOnly)
              InputChip(
                label: Text(l10n.filtersFavorites),
                onDeleted: _clearFavorites,
                visualDensity: VisualDensity.compact,
              ),
            if (_inProgressOnly)
              InputChip(
                label: Text(l10n.filtersInProgress),
                onDeleted: _clearInProgress,
                visualDensity: VisualDensity.compact,
              ),
            if (_notFollowedOnly)
              InputChip(
                label: Text(l10n.filtersNotFollowed),
                onDeleted: _clearNotFollowed,
                visualDensity: VisualDensity.compact,
              ),
            if (_sortOption != MediaSortOption.none)
              InputChip(
                label: Text(mediaSortOptionLabel(_sortOption, l10n)),
                onDeleted: _clearSort,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<CatalogueItem> items) {
    final l10n = context.l10n;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _emptyStateMessage(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return LazyPagedListView(
      // Local catalogue only — no remote API. Window resets on filter change.
      resetKey: Object.hash(
        _searchQuery,
        _mediaFilter,
        _sortOption,
        _inProgressOnly,
        _favoritesOnly,
        _notFollowedOnly,
        items.length,
        items
            .whereType<TvShow>()
            .map(
              (show) =>
                  '${show.id}:${show.status}:${show.nextEpisodeAirDate}:${show.isFollowed}',
            )
            .join('|'),
      ),
      totalItemCount: items.length,
      onRefresh: () async => _refresh(),
      itemBuilder: (_, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MediaCard(
            item: item,
            isBookmarked: true,
            isFavorite: item.isFavorite,
            onTap: () => _openDetails(item),
            onToggleFavorite: () => _toggleFavorite(item),
            onAddRemove: () async {
              final confirmed =
                  await confirmRemoveFromCatalogue(context, item);
              if (!confirmed || !mounted) return;
              await _appServices.removeFromCatalogue(item.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.removedFromCatalogue),
                ),
              );
              _refresh();
            },
          ),
        );
      },
    );
  }

  String _emptyStateMessage(AppLocalizations l10n) {
    if (_favoritesOnly &&
        _searchQuery.isEmpty &&
        !_inProgressOnly &&
        !_notFollowedOnly &&
        _mediaFilter == MediaFilter.all) {
      return l10n.catalogueNoFavorites;
    }
    if (_notFollowedOnly &&
        _searchQuery.isEmpty &&
        !_favoritesOnly &&
        !_inProgressOnly &&
        _mediaFilter != MediaFilter.filmsOnly) {
      return l10n.catalogueNoNotFollowed;
    }
    if (_inProgressOnly &&
        _searchQuery.isEmpty &&
        !_favoritesOnly &&
        !_notFollowedOnly &&
        _mediaFilter != MediaFilter.filmsOnly) {
      return l10n.catalogueNoInProgress;
    }
    if (_hasActiveFilters || _searchQuery.isNotEmpty) {
      return l10n.catalogueNoFilterMatches;
    }
    return l10n.catalogueEmpty;
  }
}
