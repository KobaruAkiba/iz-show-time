import 'package:flutter/material.dart';
import '../../widgets/film_card.dart';
import '../../widgets/tv_show_card.dart';
import '../../../data/models/catalogue_item.dart';

/// Screen for managing tracking of films and TV shows
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final bool _showFilmsFirst = true;
  bool _isGridView = false;

  final List<String> _tabs = [
    'All',
    'Films',
    'TV Shows',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showListOptions,
            tooltip: 'View Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats summary (placeholder)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('📺 TV Shows', '24'),
                _buildStatCard('🎬 Films', '18'),
                _buildStatCard('✅ Completed', '142'),
              ],
            ),
          ),

          // Tab bar
          SizedBox(
            height: 50,
            child: TabBar(
              isScrollable: true,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _tabs.map((tab) {
                return Tab(text: tab);
              }).toList(),
            ),
          ),

          // Content area
          Expanded(
            child: TabBarView(
              children: [
                _buildAllTracking(),
                _buildFilmsOnly(),
                _buildTvShowsOnly(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // In real implementation, open search and add to tracking
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Open search to add new item')),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAllTracking() {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 2)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 15, // Placeholder
        itemBuilder: (context, index) {
          if (_showFilmsFirst && index < 8) {
            return _isGridView
                ? FilmCard(
                    film: Film(id: 0, title: 'Film $index'),
                    onTap: () {},
                    onAddRemove: () {},
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    child: FilmCard(
                      film: Film(id: 0, title: 'Film $index'),
                      onTap: () {},
                      onAddRemove: () {},
                    ),
                  );
          } else if (_showFilmsFirst && index < 15) {
            return _isGridView
                ? TvShowCard(
                    tvShow: TvShow(
                        id: 0,
                        title: 'TV Show $index',
                        seasonNumber: 1,
                        episodeNumber: 1),
                    onTap: () {},
                    onAddRemove: () {},
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    child: TvShowCard(
                      tvShow: TvShow(
                          id: 0,
                          title: 'TV Show $index',
                          seasonNumber: 1,
                          episodeNumber: 1),
                      onTap: () {},
                      onAddRemove: () {},
                    ),
                  );
          }

          return _isGridView
              ? TvShowCard(
                  tvShow: TvShow(
                      id: 0,
                      title: 'TV Show $index',
                      seasonNumber: 1,
                      episodeNumber: 1),
                  onTap: () {},
                  onAddRemove: () {},
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  child: TvShowCard(
                    tvShow: TvShow(
                        id: 0,
                        title: 'TV Show $index',
                        seasonNumber: 1,
                        episodeNumber: 1),
                    onTap: () {},
                    onAddRemove: () {},
                  ),
                );
        },
      ),
    );
  }

  Widget _buildFilmsOnly() {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 2)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8, // Placeholder
        itemBuilder: (context, index) {
          return _isGridView
              ? FilmCard(
                  film: Film(id: 0, title: 'Film $index'),
                  onTap: () {},
                  onAddRemove: () {},
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  child: FilmCard(
                    film: Film(id: 0, title: 'Film $index'),
                    onTap: () {},
                    onAddRemove: () {},
                  ),
                );
        },
      ),
    );
  }

  Widget _buildTvShowsOnly() {
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 2)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 7, // Placeholder
        itemBuilder: (context, index) {
          return _isGridView
              ? TvShowCard(
                  tvShow: TvShow(
                      id: 0,
                      title: 'TV Show $index',
                      seasonNumber: 1,
                      episodeNumber: 1),
                  onTap: () {},
                  onAddRemove: () {},
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  child: TvShowCard(
                    tvShow: TvShow(
                        id: 0,
                        title: 'TV Show $index',
                        seasonNumber: 1,
                        episodeNumber: 1),
                    onTap: () {},
                    onAddRemove: () {},
                  ),
                );
        },
      ),
    );
  }

  void _showListOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
