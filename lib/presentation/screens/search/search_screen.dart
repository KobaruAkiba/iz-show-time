import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/film_card.dart';
import '../../widgets/tv_show_card.dart';
import '../../../data/models/catalogue_item.dart';

/// Search screen for finding films, TV shows, and tags
class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _controller;
  bool _isSearching = false;
  bool _isLoading = true;

  // Search results
  List<Map<String, dynamic>> _filmResults = [];
  List<Map<String, dynamic>> _tvShowResults = [];
  List<Map<String, dynamic>> _tagResults = [];

  // View toggle: films or tv shows only
  bool _showOnlyFilms = false;
  bool _showOnlyTvShows = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);

    if (widget.initialQuery.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _performSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _filmResults.clear();
      _tvShowResults.clear();
      _tagResults.clear();
      _isLoading = true;
    });

    // Simulate API call - in real implementation, use DioClient to fetch from TMDB
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
        _isLoading = false;

        // Simulated results (replace with actual API response)
        _filmResults = List.generate(
            5,
            (i) => {
                  'id': i + 1,
                  'title': '$query $i',
                  'overview': 'A thrilling movie about $query.',
                  'posterPath': '',
                  'voteAverage': (0.5 + (i % 10)).toDouble(),
                  'tags': ['action', 'drama'],
                });

        _tvShowResults = List.generate(
            3,
            (i) => {
                  'id': i + 1,
                  'name': '$query $i',
                  'overview': 'A captivating TV series about $query.',
                  'posterPath': '',
                  'voteAverage': (7.0 + (i % 3)).toDouble(),
                  'tags': ['drama', 'series'],
                });

        // Extract unique tags from results
        _tagResults = [
          {'name': 'action'},
          {'name': 'drama'},
          {'name': query},
          {'name': 'popular'},
          {'name': 'trending'},
        ];
      });
    });
  }

  void _updateQuery(String value) {
    if (mounted) {
      setState(() {
        _controller.text = value;

        if (value.isEmpty) {
          _performSearch('');
        } else {
          // Debounced search - wait 500ms
          Timer(const Duration(milliseconds: 500), () {
            _performSearch(value);
          });
        }
      });
    }
  }

  void _toggleShowFilmsOnly(bool value) {
    setState(() {
      _showOnlyFilms = value;
    });
  }

  void _toggleShowTvShowsOnly(bool value) {
    setState(() {
      _showOnlyTvShows = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_controller.text.isNotEmpty ? 'Search Results' : 'Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              setState(() {
                _isSearching = false;
                _isLoading = true;
              });
              // Clear results after short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) Navigator.pop(context);
              });
            },
          ),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Searching for "${widget.initialQuery}"...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.text.isEmpty && !_isSearching) {
      return _buildEmptyState();
    }

    if (_isLoading) {
      return _buildLoading();
    }

    // Filter results based on toggle switches
    final filmResults = _showOnlyFilms
        ? _filmResults
        : _showOnlyTvShows
            ? []
            : _filmResults;

    final tvResults = _showOnlyTvShows
        ? _tvShowResults
        : _showOnlyFilms
            ? []
            : _tvShowResults;

    final tagResults = _tagResults.where((t) {
      final query = widget.initialQuery.toLowerCase();
      return t['name']?.toString().toLowerCase().contains(query) == true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => _performSearch(_controller.text),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle filters
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.movie_filter, size: 20),
                  title: const Text('Films Only'),
                  value: _showOnlyFilms,
                  onChanged: (value) => _toggleShowFilmsOnly(value),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.tv_outlined, size: 20),
                  title: const Text('TV Shows Only'),
                  value: _showOnlyTvShows,
                  onChanged: (value) => _toggleShowTvShowsOnly(value),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            if (_filmResults.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '🎬 Films',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              // Results grid or list
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filmResults.length,
                itemBuilder: (context, index) {
                  final result = filmResults[index];
                  return FilmCard(
                    film: Film(
                      id: result['id'],
                      title: result['title'] as String,
                      overview: result['overview'] as String?,
                      posterPath: '',
                      voteAverage: result['voteAverage'] as double,
                      tags: (result['tags'] as List<dynamic>).cast<String>(),
                    ),
                    onTap: () {},
                    onAddRemove: () {},
                  );
                },
              ),

              const SizedBox(height: 16),
            ],

            if (_tvShowResults.isNotEmpty) ...[
              Text(
                '📺 TV Shows',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: tvResults.length,
                itemBuilder: (context, index) {
                  final result = tvResults[index];
                  return TvShowCard(
                    tvShow: TvShow(
                      id: result['id'],
                      title: result['name'] as String,
                      seasonNumber: 1,
                      episodeNumber: 1,
                      overview: result['overview'] as String?,
                      posterPath: '',
                      voteAverage: result['voteAverage'] as double,
                      tags: (result['tags'] as List<dynamic>).cast<String>(),
                    ),
                    onTap: () {},
                    onAddRemove: () {},
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            if (_tagResults.isNotEmpty) ...[
              Text(
                '🏷️ Popular Tags',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tagResults.map((tag) {
                  return FilterChip(
                    label: Text(tag['name'] as String),
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    onSelected: (_) {},
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 120), // Extra space for FAB
          ],
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
            'Start typing to search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for films, TV shows, or tags',
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}
