import 'package:flutter/material.dart';
import '../../widgets/media_card.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';

/// Screen for managing tracking of films and TV shows
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _appServices = AppServices();

  final List<String> _tabs = ['All', 'Films', 'TV Shows'];

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final catalogue = _appServices.catalogue;
    final films = _appServices.films;
    final tvShows = _appServices.tvShows;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Tracking'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('📺 TV Shows', '${tvShows.length}'),
                  _buildStatCard('🎬 Films', '${films.length}'),
                  _buildStatCard('✅ Total', '${catalogue.length}'),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildItemList(catalogue),
                  _buildItemList(films),
                  _buildItemList(tvShows),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Use Search to add new items')),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List<CatalogueItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No tracked items yet',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MediaCard(
              item: item,
              isBookmarked: true,
              onAddRemove: () {
                _appServices.removeFromCatalogue(item.id);
                _refresh();
              },
            ),
          );
        },
      ),
    );
  }
}
