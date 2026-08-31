import 'package:flutter/material.dart';
import '../../widgets/debounce_search_widget.dart';
import '../../widgets/media_card.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';
import '../../../core/routing/app_router.dart';

/// Main home screen showing trending content and quick access to catalogue
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  final List<CatalogueItem> _trendingItems = [];
  int _currentPageIndex = 0;
  PageController? _pageController;

  final _appServices = AppServices();

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final movies = await _appServices.tmdbService.getTrendingMovies();
      final tv = await _appServices.tmdbService.getTrendingTv();

      final combined = <CatalogueItem>[...movies, ...tv];
      combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

      if (!mounted) return;
      setState(() {
        _trendingItems
          ..clear()
          ..addAll(combined.take(12));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load trending content';
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pageController ??= PageController(viewportFraction: 0.85);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadTrending,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildQuickActionsSection(),
              const SizedBox(height: 20),
              Expanded(child: _buildTrendingSection()),
            ],
          ],
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.pushNamed(
      context,
      AppRouter.searchRoute,
      arguments: query.trim(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: DebounceSearchWidget(onSearch: _handleSearch),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter features coming soon')),
              );
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionTile(
              icon: Icons.search,
              title: 'Search TMDB',
              onTap: () => Navigator.pushNamed(context, AppRouter.searchRoute),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildQuickActionTile(
              icon: Icons.bookmark,
              title: 'My Catalogue',
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.catalogueRoute),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    if (_trendingItems.isEmpty) {
      return Center(
        child: Text(
          'No trending content available. Check your TMDB API key.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 Trending Now',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: _loadTrending,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _trendingItems.length,
            onPageChanged: (index) => setState(() => _currentPageIndex = index),
            itemBuilder: (context, index) {
              final item = _trendingItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: MediaPosterCard(
                  item: item,
                  isBookmarked: _appServices.isInCatalogue(item.id),
                  onAddRemove: () {
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
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_trendingItems.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentPageIndex ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _currentPageIndex
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
