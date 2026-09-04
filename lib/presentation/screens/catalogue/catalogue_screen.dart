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
  final _appServices = AppServices();

  bool get _hasActiveFilters => hasActiveMediaFilters(
        mediaFilter: _mediaFilter,
        sortOption: _sortOption,
        inProgressOnly: _inProgressOnly,
        favoritesOnly: _favoritesOnly,
      );

  @override
  void initState() {
    super.initState();
    _appServices.newEpisodeAlertsListenable.addListener(_onAlertsChanged);
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  @override
  void didUpdateWidget(covariant CatalogueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _appServices.newEpisodeAlertsListenable.removeListener(_onAlertsChanged);
    super.dispose();
  }

  void _onAlertsChanged() {
    if (_inProgressOnly && mounted) {
      setState(() {});
    }
  }

  List<CatalogueItem> _filterItems(List<CatalogueItem> items) {
    Iterable<CatalogueItem> filtered = items;

    if (_favoritesOnly) {
      filtered = filtered.where((item) => item.isFavorite);
    }

    if (_inProgressOnly) {
      final inProgressIds = inProgressShowIds(
        alerts: _appServices.newEpisodeAlerts,
      );
      filtered = filtered.where(
        (item) => item.isTvShow && inProgressIds.contains(item.id),
      );
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((item) => item.title.toLowerCase().contains(query));
    }

    // In Progress implies TV-only even when media filter is "All".
    final effectiveMediaFilter =
        _inProgressOnly && _mediaFilter == MediaFilter.all
            ? MediaFilter.tvOnly
            : _mediaFilter;

    return applyMediaFilters(
      filtered,
      mediaFilter: effectiveMediaFilter,
      sortOption: _sortOption,
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
      showInProgressFilter: true,
      showFavoritesFilter: true,
    );
    if (result == null || !mounted) return;
    setState(() {
      _mediaFilter = result.mediaFilter;
      _sortOption = result.sortOption;
      _inProgressOnly = result.inProgressOnly;
      _favoritesOnly = result.favoritesOnly;
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
                        hintText: 'Search catalogue...',
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
                    isActive: _hasActiveFilters,
                    onPressed: _showFiltersSheet,
                    compact: true,
                  ),
                ],
              ),
            ),
            if (_hasActiveFilters) _buildActiveFilterChips(),
            Expanded(child: _buildItemList(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
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
                label: Text(mediaFilterLabel(_mediaFilter)),
                onDeleted: _clearMediaFilter,
                visualDensity: VisualDensity.compact,
              ),
            if (_favoritesOnly)
              InputChip(
                label: const Text('Favorites'),
                onDeleted: _clearFavorites,
                visualDensity: VisualDensity.compact,
              ),
            if (_inProgressOnly)
              InputChip(
                label: const Text('In Progress'),
                onDeleted: _clearInProgress,
                visualDensity: VisualDensity.compact,
              ),
            if (_sortOption != MediaSortOption.none)
              InputChip(
                label: Text(mediaSortOptionLabel(_sortOption)),
                onDeleted: _clearSort,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<CatalogueItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _emptyStateMessage(),
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
        items.length,
        _appServices.newEpisodeAlerts.length,
      ),
      totalItemCount: items.length,
      onRefresh: () async => _refresh(),
      itemBuilder: (context, index) {
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
              final confirmed = await confirmRemoveFromCatalogue(context, item);
              if (!confirmed || !mounted) return;
              await _appServices.removeFromCatalogue(item.id);
              _refresh();
            },
          ),
        );
      },
    );
  }

  String _emptyStateMessage() {
    if (_favoritesOnly &&
        _searchQuery.isEmpty &&
        !_inProgressOnly &&
        _mediaFilter == MediaFilter.all) {
      return 'No favorites yet.\n'
          'Tap the heart on a catalogue item to mark it as favorite.';
    }
    if (_inProgressOnly &&
        _searchQuery.isEmpty &&
        _mediaFilter != MediaFilter.filmsOnly) {
      return 'No shows currently in progress.\n'
          'Register an episode, then when the next one airs it will show up here.';
    }
    if (_hasActiveFilters || _searchQuery.isNotEmpty) {
      return 'No results match your filters';
    }
    return 'Your catalogue is empty';
  }
}
