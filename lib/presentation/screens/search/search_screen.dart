import 'package:flutter/material.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/media_filters.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/confirm_remove_from_catalogue.dart';
import '../../widgets/lazy_paged_list_view.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';

/// Search screen for finding films and shows via TMDB
class SearchScreen extends StatefulWidget {
  final String initialQuery;
  final bool isActive;

  const SearchScreen({
    super.key,
    this.initialQuery = '',
    this.isActive = true,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _controller;
  bool _hasSearched = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _lastQuery = '';

  List<Film> _filmResults = [];
  List<TvShow> _tvShowResults = [];
  final Set<int> _seenIds = {};

  int _remotePage = 0;
  int _remoteTotalPages = 0;

  MediaFilter _mediaFilter = MediaFilter.all;
  MediaSortOption _sortOption = MediaSortOption.none;

  final _appServices = AppServices();

  bool get _hasActiveFilters => hasActiveMediaFilters(
        mediaFilter: _mediaFilter,
        sortOption: _sortOption,
      );

  bool get _hasMoreRemote => _remotePage > 0 && _remotePage < _remoteTotalPages;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _clearResults();
    }
  }

  void _onQueryChanged(String value) {
    setState(() {});
  }

  void _clearQuery() {
    _controller.clear();
    setState(() {});
  }

  void _clearResults() {
    setState(() {
      _hasSearched = false;
      _isLoading = false;
      _isLoadingMore = false;
      _filmResults = [];
      _tvShowResults = [];
      _seenIds.clear();
      _errorMessage = null;
      _lastQuery = '';
      _remotePage = 0;
      _remoteTotalPages = 0;
      _mediaFilter = MediaFilter.all;
      _sortOption = MediaSortOption.none;
      _controller.clear();
    });
  }

  void _resetResultBuffers() {
    _filmResults = [];
    _tvShowResults = [];
    _seenIds.clear();
    _remotePage = 0;
    _remoteTotalPages = 0;
  }

  void _appendUnique({
    required Iterable<Film> films,
    required Iterable<TvShow> tvShows,
  }) {
    for (final film in films) {
      if (_seenIds.add(film.id)) _filmResults.add(film);
    }
    for (final show in tvShows) {
      if (_seenIds.add(show.id)) _tvShowResults.add(show);
    }
  }

  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      _hasSearched = true;
      _isLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
      _lastQuery = trimmedQuery;
      _resetResultBuffers();
    });

    try {
      final localResults = _appServices.searchLocal(trimmedQuery);
      _appendUnique(films: localResults.films, tvShows: localResults.tvShows);

      final remoteResults = await _appServices.tmdbService.searchMulti(
        query: trimmedQuery,
        page: 1,
      );

      if (!mounted || _lastQuery != trimmedQuery) return;

      _appendUnique(
        films: remoteResults.films,
        tvShows: remoteResults.tvShows,
      );

      setState(() {
        _remotePage = remoteResults.page;
        _remoteTotalPages = remoteResults.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || _lastQuery != trimmedQuery) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Search failed. Check your API key and connection.';
      });
    }
  }

  Future<void> _loadMoreRemote() async {
    if (_isLoadingMore || !_hasMoreRemote || _lastQuery.isEmpty) return;

    final nextPage = _remotePage + 1;
    final query = _lastQuery;

    setState(() => _isLoadingMore = true);

    try {
      final remoteResults = await _appServices.tmdbService.searchMulti(
        query: query,
        page: nextPage,
      );

      if (!mounted || _lastQuery != query) return;

      _appendUnique(
        films: remoteResults.films,
        tvShows: remoteResults.tvShows,
      );

      setState(() {
        _remotePage = remoteResults.page;
        _remoteTotalPages = remoteResults.totalPages;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || _lastQuery != query) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _controller,
                autofocus: widget.initialQuery.isEmpty,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search films and shows...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearQuery,
                        ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'Search',
                        onPressed: () => _performSearch(_controller.text),
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onQueryChanged,
                onSubmitted: _performSearch,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    final results = _buildFilteredResults();
    final totalCount = _filmResults.length + _tvShowResults.length;

    if (results.isEmpty) {
      return Column(
        children: [
          if (totalCount > 0) _buildFiltersBar(totalCount, filteredCount: 0),
          Expanded(
            child: Center(
              child: Text(
                totalCount > 0
                    ? 'No results match your filters'
                    : 'No results for "$_lastQuery"',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      );
    }

    // With active filters, only paginate the filtered in-memory list (no extra API).
    final canLoadMoreRemote = !_hasActiveFilters && _hasMoreRemote;

    return LazyPagedListView(
      resetKey: Object.hash(_lastQuery, _mediaFilter, _sortOption),
      totalItemCount: results.length,
      hasMoreRemote: canLoadMoreRemote,
      isLoadingMore: _isLoadingMore,
      onLoadMore: canLoadMoreRemote ? _loadMoreRemote : null,
      onRefresh: () => _performSearch(_lastQuery),
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildFiltersBar(totalCount, filteredCount: results.length),
      ),
      itemBuilder: (context, index) {
        final item = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MediaCard(
            item: item,
            isBookmarked: _appServices.isInCatalogue(item.id),
            onTap: () => _openDetails(item),
            onAddRemove: () => _toggleItem(item),
          ),
        );
      },
    );
  }

  Widget _buildFiltersBar(int totalCount, {required int filteredCount}) {
    final countLabel = _hasActiveFilters && filteredCount != totalCount
        ? '$filteredCount of $totalCount'
        : '$totalCount';

    return Row(
      children: [
        Text(
          '$countLabel results',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
        const Spacer(),
        MediaFiltersButton(
          isActive: _hasActiveFilters,
          onPressed: _showFiltersSheet,
        ),
      ],
    );
  }

  Future<void> _showFiltersSheet() async {
    final result = await showMediaFiltersSheet(
      context,
      mediaFilter: _mediaFilter,
      sortOption: _sortOption,
    );
    if (result == null || !mounted) return;
    setState(() {
      _mediaFilter = result.mediaFilter;
      _sortOption = result.sortOption;
    });
  }

  List<CatalogueItem> _buildFilteredResults() {
    return applyMediaFilters(
      [..._filmResults, ..._tvShowResults],
      mediaFilter: _mediaFilter,
      sortOption: _sortOption,
    );
  }

  void _openDetails(CatalogueItem item) {
    showMediaDetailSheet(context, item);
  }

  Future<void> _toggleItem(CatalogueItem item) async {
    final wasInCatalogue = _appServices.isInCatalogue(item.id);
    if (wasInCatalogue) {
      final confirmed = await confirmRemoveFromCatalogue(context, item);
      if (!confirmed || !mounted) return;
    }

    await _appServices.toggleCatalogueItemAsync(item);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasInCatalogue ? 'Removed from catalogue' : 'Added to catalogue',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for films and shows',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a title and press Enter or the search button',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}
