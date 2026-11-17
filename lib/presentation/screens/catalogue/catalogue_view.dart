import 'package:flutter/material.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/media_card.dart';
import '../../widgets/active_media_filter_chips.dart';
import '../../widgets/media_filters.dart';
import '../../widgets/media_search_field.dart';
import '../../widgets/catalogue_stats_row.dart';
import '../../widgets/confirm_remove_from_catalogue.dart';
import '../../widgets/lazy_paged_list_view.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/notifications/show_caught_up.dart';
import '../../../core/notifications/show_in_progress.dart';
import '../../../core/services/app_services.dart';
import '../../../core/utils/catalogue_activity.dart';
import '../../../l10n/l10n.dart';

/// Body of the catalogue: stats, search, filters and the item list.
class CatalogueView extends StatefulWidget {
  final bool isActive;

  /// Called after the user changes the catalogue size (remove, details sheet).
  final VoidCallback? onCatalogueChanged;

  const CatalogueView({
    super.key,
    this.isActive = true,
    this.onCatalogueChanged,
  });

  @override
  State<CatalogueView> createState() => _CatalogueViewState();
}

class _CatalogueViewState extends State<CatalogueView> {
  String _searchQuery = '';
  MediaFilter _mediaFilter = MediaFilter.all;
  MediaSortOption _sortOption = MediaSortOption.none;
  bool _inProgressOnly = false;
  bool _favoritesOnly = false;
  bool _notFollowedOnly = false;
  bool _caughtUpOnly = false;
  bool _statsExpanded = false;
  final _appServices = AppServices();

  bool get _forcesTvOnly =>
      _inProgressOnly || _notFollowedOnly || _caughtUpOnly;

  /// Chips row: type + sheet filters (status / sort).
  bool get _hasActiveFilters => hasActiveMediaFilters(
        mediaFilter: _mediaFilter,
        sortOption: _sortOption,
        inProgressOnly: _inProgressOnly,
        favoritesOnly: _favoritesOnly,
        notFollowedOnly: _notFollowedOnly,
        caughtUpOnly: _caughtUpOnly,
      );

  /// Tune button badge: only filters controlled by the sheet (not media type).
  bool get _hasActiveSheetFilters =>
      _sortOption != MediaSortOption.none ||
      _inProgressOnly ||
      _favoritesOnly ||
      _notFollowedOnly ||
      _caughtUpOnly;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onBecameActive());
    }
  }

  @override
  void didUpdateWidget(covariant CatalogueView oldWidget) {
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

    if (_caughtUpOnly) {
      final lastRegisteredByShowId =
          lastRegisteredEpisodesByShowId(_appServices.watchHistory);
      filtered = filtered.where(
        (item) =>
            item is TvShow &&
            isShowCaughtUp(item, lastRegisteredByShowId[item.id]),
      );
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((item) => item.title.toLowerCase().contains(query));
    }

    // TV-only status filters imply TV-only even when media filter is "All".
    final effectiveMediaFilter =
        _forcesTvOnly && _mediaFilter == MediaFilter.all
            ? MediaFilter.tvOnly
            : _mediaFilter;

    return applyMediaFilters(
      filtered,
      mediaFilter: effectiveMediaFilter,
      sortOption: _sortOption,
      recencyByMediaKey: lastCatalogueActivityByMediaId(
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
      caughtUpOnly: _caughtUpOnly,
      showInProgressFilter: true,
      showFavoritesFilter: true,
      showNotFollowedFilter: true,
      showCaughtUpFilter: true,
      showMediaTypeFilter: false,
    );
    if (result == null || !mounted) return;
    setState(() {
      _sortOption = result.sortOption;
      _inProgressOnly = result.inProgressOnly;
      _favoritesOnly = result.favoritesOnly;
      _notFollowedOnly = result.notFollowedOnly;
      _caughtUpOnly = result.caughtUpOnly;
      // Sheet no longer owns media type; keep counters in sync with TV-only filters.
      if (_forcesTvOnly &&
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
        if (_caughtUpOnly) _caughtUpOnly = false;
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

  void _clearCaughtUp() {
    setState(() => _caughtUpOnly = false);
  }

  void _clearSort() {
    setState(() => _sortOption = MediaSortOption.none);
  }

  Future<void> _openDetails(CatalogueItem item) async {
    await showMediaDetailSheet(
      context,
      item,
      onWatchTimeChanged: _refresh,
    );
    if (!mounted) return;
    widget.onCatalogueChanged?.call();
  }

  Future<void> _toggleFavorite(CatalogueItem item) async {
    await _appServices.toggleFavorite(item);
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

    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _appServices.hideWatchTimeListenable,
          builder: (context, hideWatchTime, _) => CatalogueStatsRow(
            tvShowCount: tvShows.length,
            filmCount: films.length,
            totalCount: catalogue.length,
            watchTimeMinutes: watchTime,
            hideWatchTime: hideWatchTime,
            expanded: _statsExpanded,
            onToggleExpanded: () =>
                setState(() => _statsExpanded = !_statsExpanded),
            selectedFilter: _mediaFilter,
            onFilterSelected: _onMediaFilterSelected,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: MediaSearchField(
            hintText: l10n.catalogueSearchHint,
            onChanged: (value) => setState(() => _searchQuery = value),
            filtersActive: _hasActiveSheetFilters,
            onFiltersPressed: _showFiltersSheet,
          ),
        ),
        if (_hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ActiveMediaFilterChips(
              mediaFilter: _mediaFilter,
              sortOption: _sortOption,
              onClearMediaFilter: _clearMediaFilter,
              onClearSort: _clearSort,
              extraChips: _statusChips(l10n),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(child: _buildItemList(items)),
      ],
    );
  }

  /// Status chips shown between the type chip and the sort chip.
  List<Widget> _statusChips(AppLocalizations l10n) {
    return [
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
      if (_caughtUpOnly)
        InputChip(
          label: Text(l10n.filtersCaughtUp),
          onDeleted: _clearCaughtUp,
          visualDensity: VisualDensity.compact,
        ),
    ];
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
        _caughtUpOnly,
        items.length,
        items
            .whereType<TvShow>()
            .map(
              (show) =>
                  '${show.id}:${show.status}:${show.nextEpisodeAirDate}:'
                  '${show.lastAiredSeasonNumber}x${show.lastAiredEpisodeNumber}:'
                  '${show.isFollowed}',
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
              await _appServices.removeFromCatalogue(item);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.removedFromCatalogue),
                ),
              );
              _refresh();
              widget.onCatalogueChanged?.call();
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
        !_caughtUpOnly &&
        _mediaFilter == MediaFilter.all) {
      return l10n.catalogueNoFavorites;
    }
    if (_notFollowedOnly &&
        _searchQuery.isEmpty &&
        !_favoritesOnly &&
        !_inProgressOnly &&
        !_caughtUpOnly &&
        _mediaFilter != MediaFilter.filmsOnly) {
      return l10n.catalogueNoNotFollowed;
    }
    if (_inProgressOnly &&
        _searchQuery.isEmpty &&
        !_favoritesOnly &&
        !_notFollowedOnly &&
        !_caughtUpOnly &&
        _mediaFilter != MediaFilter.filmsOnly) {
      return l10n.catalogueNoInProgress;
    }
    if (_caughtUpOnly &&
        _searchQuery.isEmpty &&
        !_favoritesOnly &&
        !_inProgressOnly &&
        !_notFollowedOnly &&
        _mediaFilter != MediaFilter.filmsOnly) {
      return l10n.catalogueNoCaughtUp;
    }
    if (_hasActiveFilters || _searchQuery.isNotEmpty) {
      return l10n.catalogueNoFilterMatches;
    }
    return l10n.catalogueEmpty;
  }
}
