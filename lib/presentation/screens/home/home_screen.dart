import 'package:flutter/material.dart';
import '../../widgets/debounce_search_widget.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../core/services/app_services.dart';
import '../../../core/routing/app_router.dart';

/// Main home screen showing trending content carousel
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

  void _openDetails(CatalogueItem item) {
    showMediaDetailSheet(context, item);
  }

  @override
  Widget build(BuildContext context) {
    _pageController ??= PageController(viewportFraction: 0.82);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
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
                      Icon(
                        Icons.cloud_off,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
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
            else
              Expanded(child: _buildTrendingSection()),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Show Time',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          DebounceSearchWidget(onSearch: _handleSearch),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    if (_trendingItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No trending content available. Check your TMDB API key.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Text(
            'Trending Now',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            'Swipe to explore · tap for details',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _trendingItems.length,
            onPageChanged: (index) => setState(() => _currentPageIndex = index),
            itemBuilder: (context, index) {
              final item = _trendingItems[index];
              return AnimatedBuilder(
                animation: _pageController!,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageController!.position.haveDimensions) {
                    final page = _pageController!.page ?? index.toDouble();
                    scale = (1 - (page - index).abs() * 0.12).clamp(0.88, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: MediaPosterCard(
                    item: item,
                    isActive: index == _currentPageIndex,
                    onTap: () => _openDetails(item),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_trendingItems.length, (index) {
            final isActive = index == _currentPageIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
