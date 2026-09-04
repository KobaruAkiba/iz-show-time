import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/app_services.dart';
import '../../core/utils/duration_format.dart';
import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/media_details.dart';
import '../../data/models/season_model.dart';
import 'confirm_remove_from_catalogue.dart';

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
  List<SeasonModel> _seasons = [];
  bool _isLoadingSeasons = false;
  final Set<int> _expandedSeasons = {};

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final fetched = await _appServices.tmdbService.getMediaDetails(widget.item);

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

    if (widget.item is TvShow && (_details?.numberOfSeasons ?? 0) > 0) {
      await _loadSeasons();
    }
  }

  Future<void> _loadSeasons() async {
    setState(() => _isLoadingSeasons = true);

    final seasons = await _appServices.tmdbService.getTvSeasons(
      tvId: widget.item.id,
      numberOfSeasons: _details!.numberOfSeasons!,
    );

    if (!mounted) return;
    setState(() {
      _seasons = seasons;
      _isLoadingSeasons = false;
    });
  }

  void _notifyWatchTimeChanged() {
    widget.onWatchTimeChanged?.call();
    setState(() {});
  }

  Future<void> _toggleFilmWatched() async {
    final film = widget.item as Film;

    if (_appServices.isWatched(mediaId: film.id)) {
      final confirmed = await confirmRemoveFromCatalogue(context, film);
      if (!confirmed || !mounted) return;

      await _appServices.removeFromCatalogue(film.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from catalogue')),
      );
      _notifyWatchTimeChanged();
      return;
    }

    final runtime = _details?.runtimeMinutes ?? 0;
    if (runtime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Runtime not available for this film')),
      );
      return;
    }

    final record = await _appServices.markFilmWatched(
      film: film,
      durationMinutes: runtime,
    );

    if (!mounted) return;

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

  Future<void> _toggleFilmFavorite() async {
    await _appServices.toggleFavorite(widget.item.id);
    if (!mounted) return;
    _notifyWatchTimeChanged();
  }

  Future<void> _addEpisodeToCatalogue(EpisodeModel episode) async {
    final show = widget.item as TvShow;
    final isWatched =
        _appServices.isWatched(mediaId: show.id, episodeId: episode.id);

    if (isWatched) {
      await _appServices.unmarkEpisodeWatched(episode.id);
      _notifyWatchTimeChanged();
      return;
    }

    if (episode.isUpcoming) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode has not aired yet')),
      );
      return;
    }

    final record = await _appServices.addEpisodeToCatalogue(
      show: show,
      episode: episode,
      fallbackRuntimeMinutes: _details?.averageEpisodeRuntimeMinutes,
    );

    if (!mounted) return;

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode runtime not available')),
      );
      return;
    }

    _notifyWatchTimeChanged();
  }

  Future<void> _toggleSeasonInCatalogue(SeasonModel season) async {
    if (season.episodes.isEmpty || season.isUpcoming) return;

    final show = widget.item as TvShow;
    final allInCatalogue = season.episodes.every(
      (episode) => _appServices.isWatched(
        mediaId: show.id,
        episodeId: episode.id,
      ),
    );

    if (allInCatalogue) {
      await _appServices.removeSeasonFromCatalogue(episodes: season.episodes);
      _notifyWatchTimeChanged();
      return;
    }

    final addedCount = await _appServices.addSeasonToCatalogue(
      show: show,
      episodes: season.episodes,
      fallbackRuntimeMinutes: _details?.averageEpisodeRuntimeMinutes,
    );

    if (!mounted) return;

    if (addedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode runtime not available')),
      );
      return;
    }

    _notifyWatchTimeChanged();
  }

  void _toggleSeason(int seasonNumber) {
    setState(() {
      if (_expandedSeasons.contains(seasonNumber)) {
        _expandedSeasons.remove(seasonNumber);
      } else {
        _expandedSeasons.add(seasonNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details = _details;
    final posterPath = details?.posterPath ?? widget.item.posterPath;
    final posterUrl = ApiConstants.posterUrl(posterPath);
    final isFilm = widget.item is Film;
    final filmWatched =
        isFilm && _appServices.isWatched(mediaId: widget.item.id);
    final filmFavorite =
        isFilm && _appServices.isFavorite(widget.item.id);

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
                                label: details.isFilm ? 'Film' : 'Show',
                              ),
                            ],
                          ),
                          if (!isFilm &&
                              _appServices
                                      .watchedEpisodesCountFor(widget.item.id) >
                                  0) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_appServices.watchedEpisodesCountFor(widget.item.id)} episode(s) in catalogue',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colorScheme.primary),
                            ),
                          ],
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
                      onPressed: _toggleFilmWatched,
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
                  if (filmWatched) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _toggleFilmFavorite,
                        icon: Icon(
                          filmFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        label: Text(
                          filmFavorite
                              ? 'Favorite'
                              : 'Mark as Favorite',
                        ),
                      ),
                    ),
                  ],
                ],
                if (!isFilm) ...[
                  const SizedBox(height: 24),
                  _buildSeasonsSection(),
                ],
                if (details.director != null &&
                    details.director!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionLabel(
                    details.isFilm ? 'Director' : 'Created by',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.director!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (details.cast.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionLabel('Cast'),
                  const SizedBox(height: 12),
                  _buildCastCarousel(details.cast),
                ],
                if (details.overview != null &&
                    details.overview!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionLabel('Overview'),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCastCarousel(List<MediaCastMember> cast) {
    return SizedBox(
      height: 198,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildCastMember(cast[index]),
      ),
    );
  }

  Widget _buildCastMember(MediaCastMember member) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileUrl =
        ApiConstants.posterUrl(member.profilePath, size: ApiConstants.w342Image);
    final character = member.character;

    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 88,
              height: 110,
              child: profileUrl.isNotEmpty
                  ? Image.network(
                      profileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _castAvatarFallback(context),
                    )
                  : _castAvatarFallback(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            member.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
          if (character != null && character.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              character,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.2,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _castAvatarFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 36,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildSeasonsSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Episodes'),
        const SizedBox(height: 8),
        if (_isLoadingSeasons)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_seasons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No episodes found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          )
        else
          ..._seasons.map(_buildSeasonSection),
      ],
    );
  }

  Widget _buildSeasonSection(SeasonModel season) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = _expandedSeasons.contains(season.seasonNumber);
    final watchedInSeason = season.episodes
        .where(
          (episode) => _appServices.isWatched(
            mediaId: widget.item.id,
            episodeId: episode.id,
          ),
        )
        .length;
    final allInCatalogue =
        season.episodes.isNotEmpty && watchedInSeason == season.episodes.length;
    final canAddSeason = season.episodes.isNotEmpty && !season.isUpcoming;

    String subtitle;
    if (season.isUpcoming) {
      subtitle = season.airDate != null
          ? 'Upcoming · ${_formatShortAirDate(season.airDate!)}'
          : 'Upcoming';
    } else if (watchedInSeason > 0) {
      subtitle =
          '$watchedInSeason / ${season.episodes.length} in catalogue';
    } else {
      subtitle = '${season.episodes.length} episodes';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(
        children: [
          ListTile(
            onTap: () => _toggleSeason(season.seasonNumber),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    season.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (season.isUpcoming) ...[
                  const SizedBox(width: 8),
                  const _UpcomingBadge(),
                ],
              ],
            ),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: allInCatalogue
                      ? 'Remove season from catalogue'
                      : 'Add season to catalogue',
                  icon: Icon(
                    allInCatalogue
                        ? Icons.bookmark
                        : Icons.bookmark_add_outlined,
                    color: allInCatalogue ? colorScheme.primary : null,
                  ),
                  onPressed: canAddSeason
                      ? () => _toggleSeasonInCatalogue(season)
                      : null,
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),
          if (isExpanded)
            ...season.episodes.map(
              (episode) => _buildEpisodeTile(episode),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(EpisodeModel episode) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWatched = _appServices.isWatched(
      mediaId: widget.item.id,
      episodeId: episode.id,
    );
    final isUpcoming = episode.isUpcoming;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      leading: Text(
        episode.codeLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isWatched ? colorScheme.primary : colorScheme.onSurface,
            ),
      ),
      title: Text(
        episode.displayTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: isUpcoming
          ? Text(
              episode.airDate != null
                  ? 'Upcoming · ${_formatShortAirDate(episode.airDate!)}'
                  : 'Upcoming',
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUpcoming) ...[
            const _UpcomingBadge(),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: isUpcoming
                ? 'Episode has not aired yet'
                : isWatched
                    ? 'Remove from catalogue'
                    : 'Add episode to catalogue',
            icon: Icon(
              isWatched ? Icons.bookmark : Icons.bookmark_add_outlined,
              color: isWatched ? colorScheme.primary : null,
            ),
            onPressed:
                isUpcoming ? null : () => _addEpisodeToCatalogue(episode),
          ),
        ],
      ),
    );
  }

  String _formatShortAirDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

class _UpcomingBadge extends StatelessWidget {
  const _UpcomingBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Upcoming',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
