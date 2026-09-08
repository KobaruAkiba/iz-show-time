import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/auto_scrolling_page_carousel.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_detail_sheet.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/connection_error_view.dart';
import '../../widgets/connection_feedback.dart';
import '../../widgets/lazy_paged_list_view.dart';
import '../../../data/models/catalogue_item.dart';
import '../../../data/models/new_episode_alert.dart';
import '../../../core/network/api_error.dart';
import '../../../core/services/app_services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/l10n.dart';

/// Main home screen showing trending content carousel
class HomeScreen extends StatefulWidget {
  final bool isActive;

  const HomeScreen({super.key, this.isActive = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _carouselHeight = 400.0;

  bool _isLoading = true;
  ApiErrorType? _errorType;
  String? _errorMessage;
  final List<CatalogueItem> _trendingItems = [];
  bool _detailSheetOpen = false;
  bool _parentScrolling = false;
  int _visibleNewEpisodes = AppConstants.listPageSize;

  final _appServices = AppServices();

  @override
  void initState() {
    super.initState();
    _loadTrending();
    _appServices.newEpisodeAlertsListenable.addListener(_onNewEpisodesChanged);
  }

  void _onNewEpisodesChanged() {
    if (!mounted) return;
    final total = _appServices.newEpisodeAlerts.length;
    setState(() {
      if (total == 0) {
        _visibleNewEpisodes = AppConstants.listPageSize;
      } else if (_visibleNewEpisodes > total) {
        _visibleNewEpisodes = total;
      } else if (_visibleNewEpisodes < AppConstants.listPageSize) {
        _visibleNewEpisodes = AppConstants.listPageSize.clamp(0, total);
      }
    });
  }

  Future<void> _loadTrending() async {
    setState(() {
      _isLoading = true;
      _errorType = null;
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
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorType = e.type;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorType = ApiErrorType.networkError;
        _errorMessage = context.l10n.homeTrendingLoadFailed;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh empty-state copy when returning to Home after catalogue changes.
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _appServices.newEpisodeAlertsListenable.removeListener(_onNewEpisodesChanged);
    super.dispose();
  }

  Future<void> _openDetails(CatalogueItem item) async {
    setState(() => _detailSheetOpen = true);
    try {
      await showMediaDetailSheet(context, item);
    } finally {
      if (mounted) setState(() => _detailSheetOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(),
            if (_isLoading)
              const Expanded(
                child: ConnectionAwareLoading(),
              )
            else if (_errorMessage != null)
              Expanded(
                child: ConnectionErrorView(
                  errorType: _errorType,
                  message: _errorMessage,
                  onRetry: _loadTrending,
                ),
              )
            else
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis == Axis.vertical) {
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null &&
                          !_parentScrolling) {
                        setState(() => _parentScrolling = true);
                      } else if (notification is ScrollEndNotification &&
                          _parentScrolling) {
                        setState(() => _parentScrolling = false);
                      }
                    }

                    final alerts = _appServices.newEpisodeAlerts;
                    return handleLazyParentScroll(
                      notification: notification,
                      totalCount: alerts.length,
                      visibleCount: _visibleNewEpisodes,
                      onRevealMore: (next) {
                        if (next != _visibleNewEpisodes) {
                          setState(() => _visibleNewEpisodes = next);
                        }
                      },
                    );
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTrendingSection(),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(),
                        ),
                        _buildNewEpisodesSection(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    final l10n = context.l10n;

    if (_trendingItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.homeNoTrending,
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
            l10n.homeTrendingNow,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            l10n.homeTrendingSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ),
        const SizedBox(height: 16),
        AutoScrollingPageCarousel(
          height: _carouselHeight,
          itemCount: _trendingItems.length,
          isScreenActive: widget.isActive,
          isPaused: _detailSheetOpen || _parentScrolling,
          itemBuilder: (context, index, isActive) {
            final item = _trendingItems[index];
            return MediaPosterCard(
              item: item,
              isActive: isActive,
              onTap: () => _openDetails(item),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNewEpisodesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final alerts = _appServices.newEpisodeAlerts;
    final visibleCount = _visibleNewEpisodes.clamp(0, alerts.length);
    final visibleAlerts = alerts.take(visibleCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeNewEpisodes,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeNewEpisodesSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            _buildNewEpisodesEmptyState(colorScheme)
          else
            ...visibleAlerts.map(_buildNewEpisodeTile),
        ],
      ),
    );
  }

  Widget _buildNewEpisodesEmptyState(ColorScheme colorScheme) {
    final l10n = context.l10n;
    final hasSeries = _appServices.tvShows.isNotEmpty;
    final title = hasSeries
        ? l10n.homeNewEpisodesCaughtUpTitle
        : l10n.homeNewEpisodesEmptyTitle;
    final body = hasSeries
        ? l10n.homeNewEpisodesCaughtUpBody
        : l10n.homeNewEpisodesEmptyBody;

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
            hasSeries ? Icons.check_circle_outline : Icons.playlist_play,
            size: 40,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
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
    return context.l10n.homeAiredOn(DateFormat.yMMMd().format(date));
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
