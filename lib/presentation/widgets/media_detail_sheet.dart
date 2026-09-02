import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/app_services.dart';
import '../../core/utils/duration_format.dart';
import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/media_details.dart';

/// Opens a bottom sheet with TMDB details for the tapped carousel item.
Future<void> showMediaDetailSheet(
  BuildContext context,
  CatalogueItem item, {
  VoidCallback? onWatchTimeChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MediaDetailSheet(
      item: item,
      onWatchTimeChanged: onWatchTimeChanged,
    ),
  );
}

class MediaDetailSheet extends StatefulWidget {
  final CatalogueItem item;
  final VoidCallback? onWatchTimeChanged;

  const MediaDetailSheet({
    super.key,
    required this.item,
    this.onWatchTimeChanged,
  });

  @override
  State<MediaDetailSheet> createState() => _MediaDetailSheetState();
}

class _MediaDetailSheetState extends State<MediaDetailSheet> {
  final _appServices = AppServices();

  MediaDetails? _details;
  bool _isLoading = true;
  int _selectedSeason = 1;
  List<EpisodeModel> _episodes = [];
  bool _isLoadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final fetched =
        await _appServices.tmdbService.getMediaDetails(widget.item);

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

    if (widget.item is TvShow && _details?.numberOfSeasons != null) {
      await _loadEpisodes();
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() => _isLoadingEpisodes = true);

    final episodes = await _appServices.tmdbService.getSeasonEpisodes(
      tvId: widget.item.id,
      seasonNumber: _selectedSeason,
    );

    if (!mounted) return;
    setState(() {
      _episodes = episodes;
      _isLoadingEpisodes = false;
    });
  }

  void _notifyWatchTimeChanged() {
    widget.onWatchTimeChanged?.call();
    setState(() {});
  }

  void _markFilmWatched() {
    final film = widget.item as Film;
    final runtime = _details?.runtimeMinutes ?? 0;
    if (runtime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Runtime not available for this film')),
      );
      return;
    }

    final record = _appServices.markFilmWatched(
      film: film,
      durationMinutes: runtime,
    );

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already marked as watched')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${formatDurationMinutes(runtime)} to watch time',
        ),
      ),
    );
    _notifyWatchTimeChanged();
  }

  void _toggleEpisodeWatched(EpisodeModel episode) {
    final show = widget.item as TvShow;
    final isWatched =
        _appServices.isWatched(mediaId: show.id, episodeId: episode.id);

    if (isWatched) {
      _appServices.unmarkEpisodeWatched(episode.id);
      _notifyWatchTimeChanged();
      return;
    }

    final record = _appServices.markEpisodeWatched(
      show: show,
      episode: episode,
      fallbackRuntimeMinutes: _details?.averageEpisodeRuntimeMinutes,
    );

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode runtime not available')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${formatDurationMinutes(record.durationMinutes)} to watch time',
        ),
      ),
    );
    _notifyWatchTimeChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details = _details;
    final posterPath = details?.posterPath ?? widget.item.posterPath;
    final posterUrl = ApiConstants.posterUrl(posterPath);
    final isFilm = widget.item is Film;
    final filmWatched = isFilm &&
        _appServices.isWatched(mediaId: widget.item.id);

    return DraggableScrollableSheet(
      initialChildSize: isFilm ? 0.55 : 0.75,
      minChildSize: 0.35,
      maxChildSize: 0.92,
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
                              if (details.isFilm &&
                                  details.formattedRuntime != null)
                                _MetaChip(
                                  icon: Icons.schedule,
                                  label: details.formattedRuntime!,
                                ),
                              if (!details.isFilm &&
                                  details.formattedSeasons != null)
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
                if (isFilm) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: filmWatched ? null : _markFilmWatched,
                      icon: Icon(
                        filmWatched
                            ? Icons.check_circle
                            : Icons.play_circle_outline,
                      ),
                      label: Text(
                        filmWatched ? 'Watched' : 'Mark as Watched',
                      ),
                    ),
                  ),
                ],
                if (details.director != null &&
                    details.director!.isNotEmpty) ...[
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
                if (!isFilm) ...[
                  const SizedBox(height: 24),
                  _buildEpisodesSection(details),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEpisodesSection(MediaDetails details) {
    final colorScheme = Theme.of(context).colorScheme;
    final seasonCount = details.numberOfSeasons ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Episodes',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (seasonCount > 1)
              DropdownButton<int>(
                value: _selectedSeason,
                underline: const SizedBox.shrink(),
                items: List.generate(seasonCount, (index) {
                  final season = index + 1;
                  return DropdownMenuItem(
                    value: season,
                    child: Text('Season $season'),
                  );
                }),
                onChanged: (season) {
                  if (season == null) return;
                  setState(() => _selectedSeason = season);
                  _loadEpisodes();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingEpisodes)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_episodes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No episodes found for this season.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          )
        else
          ..._episodes.map(_buildEpisodeTile),
      ],
    );
  }

  Widget _buildEpisodeTile(EpisodeModel episode) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWatched = _appServices.isWatched(
      mediaId: widget.item.id,
      episodeId: episode.id,
    );
    final runtime = episode.runtimeMinutes ??
        _details?.averageEpisodeRuntimeMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isWatched
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          child: Text(
            '${episode.episodeNumber}',
            style: TextStyle(
              color: isWatched
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          episode.name.isNotEmpty
              ? episode.name
              : 'Episode ${episode.episodeNumber}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: runtime != null && runtime > 0
            ? Text(formatDurationMinutes(runtime))
            : null,
        trailing: IconButton(
          tooltip: isWatched ? 'Unmark as watched' : 'Mark as watched',
          icon: Icon(
            isWatched ? Icons.check_circle : Icons.check_circle_outline,
            color: isWatched ? colorScheme.primary : null,
          ),
          onPressed: () => _toggleEpisodeWatched(episode),
        ),
      ),
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
