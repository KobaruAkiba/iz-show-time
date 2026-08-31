import 'package:flutter/material.dart';
import '../../widgets/media_card.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';

/// Screen displaying the user's catalogue of films and TV shows
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final _appServices = AppServices();

  final List<String> _tabs = ['All', 'Films', 'TV Shows', 'In Progress'];
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

  List<CatalogueItem> _filterItems(List<CatalogueItem> items) {
    if (_searchQuery.isEmpty) return items;
    final query = _searchQuery.toLowerCase();
    return items
        .where((item) => item.title.toLowerCase().contains(query))
        .toList();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
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
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemList(_filterItems(_appServices.catalogue)),
                _buildItemList(_filterItems(_appServices.films)),
                _buildItemList(_filterItems(_appServices.tvShows)),
                _buildItemList(
                  _filterItems(_appServices.tvShows),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Use Search to add items')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add to Catalogue'),
      ),
    );
  }

  Widget _buildItemList(List<CatalogueItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Your catalogue is empty',
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
