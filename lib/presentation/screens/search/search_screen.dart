import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/media_card.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';
import '../../../core/constants/app_constants.dart';

/// Search screen for finding films and TV shows via TMDB
class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _isLoading = false;
  String? _errorMessage;

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
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _isLoading = false;
        _filmResults = [];
        _tvShowResults = [];
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceDelayMs),
      () => _performSearch(value.trim()),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _errorMessage = null;
      _filmResults = [];
      _tvShowResults = [];
    });

    try {
      final results = await _appServices.tmdbService.searchMulti(query: query);
      if (!mounted) return;
      setState(() {
        _filmResults = results.films;
        _tvShowResults = results.tvShows;
        _isSearching = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _isLoading = false;
        _errorMessage = 'Search failed. Check your API key and connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery.isEmpty,
              decoration: InputDecoration(
                hintText: 'Search films and TV shows...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
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
    );
  }

  Widget _buildBody() {
    if (_controller.text.trim().isEmpty && !_isSearching) {
      return _buildEmptyState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    final filmResults =
        _showOnlyTvShows ? <Film>[] : _filmResults;
    final tvResults =
        _showOnlyFilms ? <TvShow>[] : _tvShowResults;

    if (filmResults.isEmpty && tvResults.isEmpty) {
      return Center(
        child: Text(
          'No results for "${_controller.text}"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _performSearch(_controller.text.trim()),
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
          if (filmResults.isNotEmpty) ...[
            Text(
              '🎬 Films',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...filmResults.map((film) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MediaCard(
                    item: film,
                    isBookmarked: _appServices.isInCatalogue(film.id),
                    onAddRemove: () => _toggleItem(film),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          if (tvResults.isNotEmpty) ...[
            Text(
              '📺 TV Shows',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...tvResults.map((show) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MediaCard(
                    item: show,
                    isBookmarked: _appServices.isInCatalogue(show.id),
                    onAddRemove: () => _toggleItem(show),
                  ),
                )),
          ],
        ],
      ),
    );
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
            'Start typing to search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search TMDB for films and TV shows',
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
