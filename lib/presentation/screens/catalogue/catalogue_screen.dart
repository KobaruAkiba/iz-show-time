import 'package:flutter/material.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/media_card.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/catalogue_stats_row.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';
import '../../../core/debug/agent_debug_log.dart';

/// Screen displaying the user's catalogue of films and TV shows
class CatalogueScreen extends StatefulWidget {
  final bool isActive;

  const CatalogueScreen({super.key, this.isActive = true});

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

  void _openDetails(CatalogueItem item) {
    showMediaDetailSheet(
      context,
      item,
      onWatchTimeChanged: _refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final films = _appServices.films;
    final tvShows = _appServices.tvShows;
    final catalogue = _appServices.catalogue;
    final watchTime = _appServices.totalWatchTimeMinutes;
    // #region agent log
    AgentDebugLog.log(
      location: 'catalogue_screen.dart:build',
      message: 'catalogue screen rendered',
      hypothesisId: 'B',
      data: {
        'watchTimeMinutes': watchTime,
        'catalogueSize': catalogue.length,
        'filmCount': films.length,
      },
    );
    // #endregion

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
                  _buildItemList(_filterItems(catalogue)),
                  _buildItemList(_filterItems(films)),
                  _buildItemList(_filterItems(tvShows)),
                  _buildItemList(_filterItems(tvShows)),
                ],
              ),
            ),
          ],
        ),
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
              onTap: () => _openDetails(item),
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
