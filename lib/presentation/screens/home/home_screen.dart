import 'package:flutter/material.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/app_page_header.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../data/models/new_episode_alert.dart';
import '../../../core/services/app_services.dart';
import '../../../core/constants/api_constants.dart';

/// Main home screen showing trending content carousel
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _carouselHeight = 400.0;

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
    _appServices.newEpisodeAlertsListenable.addListener(_onNewEpisodesChanged);
  }

  void _onNewEpisodesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTrending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final combined = await _appServices.tmdbService.getTrendingAll();
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
    _appServices.newEpisodeAlertsListenable.removeListener(_onNewEpisodesChanged);
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
            const AppPageHeader(),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrendingSection(),
                      _buildNewEpisodesSection(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    if (_trendingItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
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
        SizedBox(
          height: _carouselHeight,
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNewEpisodesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final alerts = _appServices.newEpisodeAlerts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Episodes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest releases after your last registered episode',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            _buildNewEpisodesEmptyState(colorScheme)
          else
            ...alerts.map(_buildNewEpisodeTile),
        ],
      ),
    );
  }

  Widget _buildNewEpisodesEmptyState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.playlist_play,
            size: 40,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing here yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
                Text(
                  'Register at least one episode in your catalogue. New releases after that S/E will appear here.',
                  textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewEpisodeTile(NewEpisodeAlert alert) {
    final colorScheme = Theme.of(context).colorScheme;
    final posterUrl = ApiConstants.posterUrl(alert.showPosterPath);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNewEpisodeDetails(alert),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 84,
                    child: posterUrl.isNotEmpty
                        ? Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _posterFallback(),
                          )
                        : _posterFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.showTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alert.episodeCode} · ${alert.displayTitle}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (alert.airDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatAirDate(alert.airDate!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _posterFallback() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.live_tv,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
      ),
    );
  }

  String _formatAirDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Aired ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _openNewEpisodeDetails(NewEpisodeAlert alert) {
    final show = TvShow(
      id: alert.showId,
      title: alert.showTitle,
      posterPath: alert.showPosterPath,
    );
    showMediaDetailSheet(context, show);
  }
}
