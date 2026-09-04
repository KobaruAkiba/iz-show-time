import 'package:flutter/material.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_filters.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/catalogue_stats_row.dart';
import '../../widgets/confirm_remove_from_catalogue.dart';
import '../../widgets/lazy_paged_list_view.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';

/// Screen displaying the user's catalogue of films and shows
class CatalogueScreen extends StatefulWidget {
  final bool isActive;

  const CatalogueScreen({super.key, this.isActive = true});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  MediaFilter _mediaFilter = MediaFilter.all;
  MediaSortOption _sortOption = MediaSortOption.none;
  final _appServices = AppServices();

  final List<String> _tabs = ['All', 'Films', 'Shows', 'In Progress'];
  late TabController _tabController;

  bool get _hasActiveFilters => hasActiveMediaFilters(
        mediaFilter: _mediaFilter,
        sortOption: _sortOption,
      );

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
    Iterable<CatalogueItem> filtered = items;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((item) => item.title.toLowerCase().contains(query));
    }
    return applyMediaFilters(
      filtered,
      mediaFilter: _mediaFilter,
      sortOption: _sortOption,
    );
  }

  void _refresh() => setState(() {});

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
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
                  const SizedBox(width: 8),
                  MediaFiltersButton(
                    isActive: _hasActiveFilters,
                    onPressed: _showFiltersSheet,
                    compact: true,
                  ),
                ],
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
                  _buildItemList(_filterItems(catalogue), tabIndex: 0),
                  _buildItemList(_filterItems(films), tabIndex: 1),
                  _buildItemList(_filterItems(tvShows), tabIndex: 2),
                  _buildItemList(_filterItems(tvShows), tabIndex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<CatalogueItem> items, {required int tabIndex}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          _hasActiveFilters || _searchQuery.isNotEmpty
              ? 'No results match your filters'
              : 'Your catalogue is empty',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return LazyPagedListView(
      // Local catalogue only — no remote API. Window resets on filter/tab data change.
      resetKey: Object.hash(
        tabIndex,
        _searchQuery,
        _mediaFilter,
        _sortOption,
        items.length,
      ),
      totalItemCount: items.length,
      onRefresh: () async => _refresh(),
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MediaCard(
            item: item,
            isBookmarked: true,
            onTap: () => _openDetails(item),
            onAddRemove: () async {
              final confirmed = await confirmRemoveFromCatalogue(context, item);
              if (!confirmed || !mounted) return;
              await _appServices.removeFromCatalogue(item.id);
              _refresh();
            },
          ),
        );
      },
    );
  }
}
