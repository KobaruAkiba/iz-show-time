import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/app_services.dart';
import '../../data/models/catalogue_item.dart';
import '../../data/models/media_details.dart';

/// Opens a bottom sheet with TMDB details for the tapped carousel item.
Future<void> showMediaDetailSheet(
  BuildContext context,
  CatalogueItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MediaDetailSheet(item: item),
  );
}

class MediaDetailSheet extends StatefulWidget {
  final CatalogueItem item;

  const MediaDetailSheet({super.key, required this.item});

  @override
  State<MediaDetailSheet> createState() => _MediaDetailSheetState();
}

class _MediaDetailSheetState extends State<MediaDetailSheet> {
  MediaDetails? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final fetched =
        await AppServices().tmdbService.getMediaDetails(widget.item);

    if (!mounted) return;
    setState(() {
      _details = fetched ??
          MediaDetails(
            title: widget.item.title,
            overview: widget.item.overview,
            posterPath: widget.item.posterPath,
            isFilm: widget.item is Film,
          );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details = _details;
    final posterPath = details?.posterPath ?? widget.item.posterPath;
    final posterUrl = ApiConstants.posterUrl(posterPath);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (details != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 150,
                        child: posterUrl.isNotEmpty
                            ? Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _posterFallback(context),
                              )
                            : _posterFallback(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (details.year != null)
                                _MetaChip(
                                  icon: Icons.calendar_today,
                                  label: details.year.toString(),
                                ),
                              if (details.isFilm && details.formattedRuntime != null)
                                _MetaChip(
                                  icon: Icons.schedule,
                                  label: details.formattedRuntime!,
                                ),
                              if (!details.isFilm && details.formattedSeasons != null)
                                _MetaChip(
                                  icon: Icons.layers,
                                  label: details.formattedSeasons!,
                                ),
                              _MetaChip(
                                icon: details.isFilm
                                    ? Icons.movie_filter
                                    : Icons.tv,
                                label: details.isFilm ? 'Film' : 'TV Show',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (details.director != null && details.director!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    details.isFilm ? 'Director' : 'Created by',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.director!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (details.overview != null &&
                    details.overview!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.overview!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _posterFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        widget.item is Film ? Icons.movie : Icons.tv,
        size: 40,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
