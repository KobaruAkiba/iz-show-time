import 'package:flutter/material.dart';
import '../../widgets/film_card.dart';
import '../../widgets/tv_show_card.dart';
import '../../../data/models/catalogue_item.dart';

/// Screen displaying the user's catalogue of films and TV shows
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen>
    with SingleTickerProviderStateMixin {
  bool _isGridView = true;
  String _searchQuery = '';
  int _currentTabIndex = 0;

  final List<String> _tabs = [
    'All',
    'Films',
    'TV Shows',
    'In Progress',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _buildTabItems(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllContent(),
                _buildFilmsOnly(),
                _buildTvShowsOnly(),
                _buildInProgress(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add to Catalogue'),
      ),
    );
  }

  List<Widget> _buildTabItems() {
    final widgets = <Widget>[];
    for (int i = 0; i < _tabs.length; i++) {
      widgets.add(GestureDetector(
        onTap: () => setState(() => _currentTabIndex = i),
        child: Tab(text: _tabs[i]),
      ));
    }
    return widgets;
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search catalogue...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _buildFilterChip('🎬 Film'),
              const SizedBox(width: 4),
              _buildFilterChip('📺 TV'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildAllContent() {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 2)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 12,
        itemBuilder: (context, index) {
          if (_searchQuery.isNotEmpty) {
            return _buildSearchResultItem(index);
          }

          final isFilm = index % 2 == 0;
          if (index < 5) {
            return _isGridView
                ? _buildGridFilmCard(index)
                : _buildListFilmCard(index);
          } else {
            return _isGridView
                ? _buildGridTvShowCard(index)
                : _buildListTvShowCard(index);
          }
        },
      ),
    );
  }

  Widget _buildFilmsOnly() {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 2)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return _isGridView
              ? _buildGridFilmCard(index)
              : _buildListFilmCard(index);
        },
      ),
    );
  }

  Widget _buildTvShowsOnly() {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 2)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return _isGridView
              ? _buildGridTvShowCard(index)
              : _buildListTvShowCard(index);
        },
      ),
    );
  }

  Widget _buildInProgress() {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 2)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index < 2) {
            return _isGridView
                ? _buildGridFilmCard(index)
                : _buildListFilmCard(index);
          } else {
            return _isGridView
                ? _buildGridTvShowCard(index + 2)
                : _buildListTvShowCard(index + 2);
          }
        },
      ),
    );
  }

  Widget _buildSearchResultItem(int index) {
    if (index < 5) {
      return _isGridView
          ? _buildGridFilmCard(index)
          : _buildListFilmCard(index);
    } else {
      return _isGridView
          ? _buildGridTvShowCard(index)
          : _buildListTvShowCard(index);
    }
  }

  Widget _buildGridFilmCard(int index) {
    return FilmCard(
      film: const Film(id: 0, title: 'Sample Film Title'),
      onTap: () => _showItemDetails(index),
      onAddRemove: () {},
    );
  }

  Widget _buildGridTvShowCard(int index) {
    return TvShowCard(
      tvShow: const TvShow(id: 0, title: 'Sample TV Show Title', seasonNumber: 1, episodeNumber: 1),
      onTap: () => _showItemDetails(index),
      onAddRemove: () {},
    );
  }

  Widget _buildListFilmCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      child: FilmCard(
        film: const Film(id: 0, title: 'Sample Film Title'),
        onTap: () => _showItemDetails(index),
        onAddRemove: () {},
      ),
    );
  }

  Widget _buildListTvShowCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      child: TvShowCard(
        tvShow: const TvShow(id: 0, title: 'Sample TV Show Title', seasonNumber: 1, episodeNumber: 1),
        onTap: () => _showItemDetails(index),
        onAddRemove: () {},
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        spacing: 12,
        children: [
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Grid View'),
            onTap: () {
              setState(() {
                _isGridView = true;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_list),
            title: const Text('List View'),
            onTap: () {
              setState(() {
                _isGridView = false;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showItemDetails(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing item ${index + 1}')),
    );
  }
}
