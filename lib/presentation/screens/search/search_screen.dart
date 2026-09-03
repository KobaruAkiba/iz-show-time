import 'package:flutter/material.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/app_page_header.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';

enum SearchMediaFilter { all, filmsOnly, tvOnly }

enum SearchSortOption {
  none,
  titleAsc,
  titleDesc,
  ratingAsc,
  ratingDesc,
}

/// Search screen for finding films and TV shows via TMDB
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
  String? _errorMessage;
  String _lastQuery = '';

  List<Film> _filmResults = [];
  List<TvShow> _tvShowResults = [];

  SearchMediaFilter _mediaFilter = SearchMediaFilter.all;
  SearchSortOption _sortOption = SearchSortOption.none;

  final _appServices = AppServices();

  bool get _hasActiveFilters =>
      _mediaFilter != SearchMediaFilter.all ||
      _sortOption != SearchSortOption.none;

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
      _filmResults = [];
      _tvShowResults = [];
      _errorMessage = null;
      _lastQuery = '';
      _mediaFilter = SearchMediaFilter.all;
      _sortOption = SearchSortOption.none;
      _controller.clear();
    });
  }

  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      _hasSearched = true;
      _isLoading = true;
      _errorMessage = null;
      _lastQuery = trimmedQuery;
      _filmResults = [];
      _tvShowResults = [];
    });

    try {
      final localResults = _appServices.searchLocal(trimmedQuery);
      final remoteResults =
          await _appServices.tmdbService.searchMulti(query: trimmedQuery);

      if (!mounted || _lastQuery != trimmedQuery) return;

      final films = <Film>[];
      final tvShows = <TvShow>[];
      final seenIds = <int>{};

      for (final film in localResults.films) {
        if (seenIds.add(film.id)) films.add(film);
      }
      for (final show in localResults.tvShows) {
        if (seenIds.add(show.id)) tvShows.add(show);
      }
      for (final film in remoteResults.films) {
        if (seenIds.add(film.id)) films.add(film);
      }
      for (final show in remoteResults.tvShows) {
        if (seenIds.add(show.id)) tvShows.add(show);
      }

      setState(() {
        _filmResults = films;
        _tvShowResults = tvShows;
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
                  hintText: 'Search films and TV shows...',
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

    return RefreshIndicator(
      onRefresh: () => _performSearch(_lastQuery),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFiltersBar(totalCount, filteredCount: results.length),
          const SizedBox(height: 8),
          ...results.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MediaCard(
                item: item,
                showTypeBadge: true,
                formatZeroRatingAsNd: true,
                isBookmarked: _appServices.isInCatalogue(item.id),
                onTap: () => _openDetails(item),
                onAddRemove: () => _toggleItem(item),
              ),
            ),
          ),
        ],
      ),
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
        Badge(
          isLabelVisible: _hasActiveFilters,
          label: const Text(''),
          smallSize: 8,
          child: OutlinedButton.icon(
            onPressed: _showFiltersSheet,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Filters & sort'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFiltersSheet() async {
    var mediaFilter = _mediaFilter;
    var sortOption = _sortOption;

    await showModalBottomSheet<void>(
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
                  SegmentedButton<SearchMediaFilter>(
                    segments: const [
                      ButtonSegment(
                        value: SearchMediaFilter.all,
                        label: Text('All'),
                        icon: Icon(Icons.grid_view, size: 18),
                      ),
                      ButtonSegment(
                        value: SearchMediaFilter.filmsOnly,
                        label: Text('Films'),
                        icon: Icon(Icons.movie_filter, size: 18),
                      ),
                      ButtonSegment(
                        value: SearchMediaFilter.tvOnly,
                        label: Text('TV'),
                        icon: Icon(Icons.tv_outlined, size: 18),
                      ),
                    ],
                    selected: {mediaFilter},
                    onSelectionChanged: (selection) {
                      setSheetState(() => mediaFilter = selection.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sort by',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  ...SearchSortOption.values.map(
                    (option) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        sortOption == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                      ),
                      title: Text(_sortOptionLabel(option)),
                      onTap: () =>
                          setSheetState(() => sortOption = option),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            mediaFilter = SearchMediaFilter.all;
                            sortOption = SearchSortOption.none;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _mediaFilter = mediaFilter;
                            _sortOption = sortOption;
                          });
                          Navigator.pop(context);
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

  String _sortOptionLabel(SearchSortOption option) {
    return switch (option) {
      SearchSortOption.none => 'Default order',
      SearchSortOption.titleAsc => 'Title (A → Z)',
      SearchSortOption.titleDesc => 'Title (Z → A)',
      SearchSortOption.ratingDesc => 'Rating (high → low)',
      SearchSortOption.ratingAsc => 'Rating (low → high)',
    };
  }

  List<CatalogueItem> _buildFilteredResults() {
    final results = <CatalogueItem>[];
    switch (_mediaFilter) {
      case SearchMediaFilter.all:
        results.addAll(_filmResults);
        results.addAll(_tvShowResults);
      case SearchMediaFilter.filmsOnly:
        results.addAll(_filmResults);
      case SearchMediaFilter.tvOnly:
        results.addAll(_tvShowResults);
    }

    switch (_sortOption) {
      case SearchSortOption.none:
        break;
      case SearchSortOption.titleAsc:
        results.sort(
          (a, b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case SearchSortOption.titleDesc:
        results.sort(
          (a, b) =>
              b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
      case SearchSortOption.ratingAsc:
        results.sort((a, b) => a.voteAverage.compareTo(b.voteAverage));
      case SearchSortOption.ratingDesc:
        results.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }

    return results;
  }

  void _openDetails(CatalogueItem item) {
    showMediaDetailSheet(context, item);
  }

  Future<void> _toggleItem(CatalogueItem item) async {
    await _appServices.toggleCatalogueItemAsync(item);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _appServices.isInCatalogue(item.id)
              ? 'Added to catalogue'
              : 'Removed from catalogue',
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for films and TV shows',
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
