import 'package:flutter/material.dart';
import '../../widgets/media_card.dart';
import '../../widgets/app_page_header.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';

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

  bool _showOnlyFilms = false;
  bool _showOnlyTvShows = false;

  final _appServices = AppServices();

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
      _showOnlyFilms = false;
      _showOnlyTvShows = false;
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
      final hasCachedRemote =
          _appServices.tmdbService.hasCachedSearch(trimmedQuery);
      final shouldFetchRemote =
          !hasCachedRemote && localResults.films.isEmpty && localResults.tvShows.isEmpty;

      final remoteResults = shouldFetchRemote || hasCachedRemote
          ? await _appServices.tmdbService.searchMulti(query: trimmedQuery)
          : (films: <Film>[], tvShows: <TvShow>[]);

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

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results for "$_lastQuery"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _performSearch(_lastQuery),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.movie_filter, size: 20),
                  title: const Text('Films Only'),
                  value: _showOnlyFilms,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyFilms = value;
                      if (value) _showOnlyTvShows = false;
                    });
                  },
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.tv_outlined, size: 20),
                  title: const Text('TV Only'),
                  value: _showOnlyTvShows,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyTvShows = value;
                      if (value) _showOnlyFilms = false;
                    });
                  },
                ),
              ),
            ],
          ),
          ...results.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MediaCard(
                item: item,
                showTypeBadge: true,
                formatZeroRatingAsNd: true,
                isBookmarked: _appServices.isInCatalogue(item.id),
                onAddRemove: () => _toggleItem(item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CatalogueItem> _buildFilteredResults() {
    final results = <CatalogueItem>[];
    if (!_showOnlyTvShows) results.addAll(_filmResults);
    if (!_showOnlyFilms) results.addAll(_tvShowResults);
    return results;
  }

  void _toggleItem(CatalogueItem item) {
    _appServices.toggleCatalogueItem(item);
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
