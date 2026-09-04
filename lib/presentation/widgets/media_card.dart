import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../data/models/catalogue_item.dart';
import '../../core/constants/api_constants.dart';

/// Shared card widget for films and shows
class MediaCard extends StatelessWidget {
  final CatalogueItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddRemove;
  final VoidCallback? onToggleFavorite;
  final bool isBookmarked;
  final bool isFavorite;

  const MediaCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAddRemove,
    this.onToggleFavorite,
    this.isBookmarked = false,
    this.isFavorite = false,
  });

  bool get _isFilm => item is Film;

  String _formatRating(double voteAverage) {
    if (voteAverage == 0) return 'N/D';
    return voteAverage.toStringAsFixed(1);
  }

  String get _typeLabel => _isFilm ? 'Film' : 'Show';

  String? _posterBadgeLabel() {
    if (_isFilm) return null;
    final watchedCount = AppServices().watchedEpisodesCountFor(item.id);
    if (watchedCount <= 0) return null;
    return watchedCount == 1 ? '1 ep' : '$watchedCount ep';
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = ApiConstants.posterUrl(item.posterPath);
    final badgeLabel = _posterBadgeLabel();
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: posterUrl.isNotEmpty
                            ? Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _placeholder(context),
                              )
                            : _placeholder(context),
                      ),
                    ),
                    if (badgeLabel != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TypeBadge(
                            icon: _isFilm ? Icons.movie_filter : Icons.tv,
                            label: _typeLabel,
                          ),
                          const SizedBox(width: 8),
                          _RatingBadge(
                            rating: _formatRating(item.voteAverage),
                          ),
                        ],
                      ),
                      if (item.overview != null &&
                          item.overview!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.overview!.length > 100
                              ? '${item.overview!.substring(0, 100)}...'
                              : item.overview!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (onToggleFavorite != null)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 24,
                  ),
                  color: isFavorite
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  onPressed: onToggleFavorite,
                ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 24,
                ),
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                onPressed: onAddRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(_isFilm ? Icons.movie_filter : Icons.tv),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TypeBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 12,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            rating,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Poster card for the Home carousel — tappable, no action buttons.
class MediaPosterCard extends StatelessWidget {
  final CatalogueItem item;
  final VoidCallback? onTap;
  final bool isActive;

  const MediaPosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.isActive = false,
  });

  bool get _isFilm => item is Film;

  String get _typeLabel => _isFilm ? 'Film' : 'Show';

  String _formatRating(double voteAverage) {
    if (voteAverage == 0) return 'N/D';
    return voteAverage.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = ApiConstants.posterUrl(item.posterPath);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isActive ? 0.25 : 0.08,
                ),
                blurRadius: isActive ? 20 : 8,
                offset: Offset(0, isActive ? 8 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (posterUrl.isNotEmpty)
                  Image.network(
                    posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(context),
                  )
                else
                  _fallback(context),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeBadge(
                        icon: _isFilm ? Icons.movie_filter : Icons.tv,
                        label: _typeLabel,
                      ),
                      const SizedBox(height: 8),
                      _RatingBadge(
                        rating: _formatRating(item.voteAverage),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Tap for details',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          _isFilm ? Icons.movie : Icons.tv,
          size: 48,
          color: Colors.white70,
        ),
      ),
    );
  }
}
