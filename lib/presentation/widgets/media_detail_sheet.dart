import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_error.dart';
import '../../core/network/network_feedback.dart';
import '../../core/services/app_services.dart';
import '../../data/models/catalogue_item.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/media_details.dart';
import '../../data/models/season_model.dart';
import '../../l10n/l10n.dart';
import 'app_network_image.dart';
import 'confirm_remove_from_catalogue.dart';
import 'season_jump_button.dart';
import 'skeleton.dart';

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
  /// Seasons listed from the show payload; episodes load on expansion.
  List<SeasonSummary> _seasonSummaries = const [];
  final Map<int, SeasonModel> _loadedSeasons = {};
  final Map<int, Future<SeasonModel?>> _seasonLoads = {};
  final Set<int> _failedSeasons = {};
  final Set<int> _expandedSeasons = {};

  /// True while a catalogue action runs: its buttons are disabled so a
  /// second tap cannot start the same action twice.
  bool _busy = false;

  /// Season jump button: target to show, and the anchors it measures.
  final _jumpTarget = ValueNotifier<SeasonJumpTarget?>(null);
  final _viewportKey = GlobalKey();
  final Map<int, _SeasonAnchors> _seasonAnchors = {};
  ScrollController? _sheetScrollController;
  bool _jumpUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _jumpTarget.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
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

      if (fetched != null &&
          widget.item is TvShow &&
          _appServices.isInCatalogue(widget.item)) {
        await _appServices.applyTvShowAiringDetails(widget.item.id, fetched);
        if (!mounted) return;
      }

      if (widget.item is TvShow) {
        setState(() => _seasonSummaries = _summariesFor(_details));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _details = MediaDetails(
          title: widget.item.title,
          overview: widget.item.overview,
          posterPath: widget.item.posterPath,
          isFilm: widget.item is Film,
        );
        _isLoading = false;
      });
      NetworkFeedback.showError(e.type, message: e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _details = MediaDetails(
          title: widget.item.title,
          overview: widget.item.overview,
          posterPath: widget.item.posterPath,
          isFilm: widget.item is Film,
        );
        _isLoading = false;
      });
      NetworkFeedback.showError(ApiErrorType.networkError);
    }
  }

  /// Season list from the payload, or 1..N when TMDB sent only the count.
  List<SeasonSummary> _summariesFor(MediaDetails? details) {
    if (details == null) return const [];
    if (details.seasonSummaries.isNotEmpty) return details.seasonSummaries;
    return [
      for (var number = 1; number <= (details.numberOfSeasons ?? 0); number++)
        // Count unknown: 1 keeps the season from reading as upcoming.
        SeasonSummary(seasonNumber: number, episodeCount: 1),
    ];
  }

  /// Loads one season's episodes once; null when the request failed.
  Future<SeasonModel?> _ensureSeasonLoaded(int seasonNumber) {
    final loaded = _loadedSeasons[seasonNumber];
    if (loaded != null) return Future.value(loaded);
    return _seasonLoads[seasonNumber] ??= _loadSeason(seasonNumber);
  }

  Future<SeasonModel?> _loadSeason(int seasonNumber) async {
    setState(() => _failedSeasons.remove(seasonNumber));
    try {
      final season = await _appServices.tmdbService.getSeason(
            tvId: widget.item.id,
            seasonNumber: seasonNumber,
          ) ??
          SeasonModel(seasonNumber: seasonNumber, episodes: const []);
      if (mounted) setState(() => _loadedSeasons[seasonNumber] = season);
      return season;
    } catch (error) {
      if (mounted) {
        setState(() => _failedSeasons.add(seasonNumber));
        NetworkFeedback.showErrorFrom(error);
      }
      return null;
    } finally {
      _seasonLoads.remove(seasonNumber);
      if (mounted) setState(() {});
    }
  }

  /// Runs a catalogue action with its buttons disabled.
  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  VoidCallback? _guarded(Future<void> Function() action) =>
      _busy ? null : () => _runAction(action);

  void _notifyWatchTimeChanged() {
    // Callers reach this after awaits: the sheet may be closed by then.
    if (!mounted) return;
    widget.onWatchTimeChanged?.call();
    setState(() {});
  }

  Future<void> _toggleFilmWatched() async {
    final film = widget.item as Film;
    final l10n = context.l10n;

    if (_appServices.isWatched(mediaId: film.id)) {
      final confirmed = await confirmRemoveFromCatalogue(context, film);
      if (!confirmed || !mounted) return;

      await _appServices.removeFromCatalogue(film);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.removedFromCatalogue)),
      );
      _notifyWatchTimeChanged();
      return;
    }

    final runtime = _details?.runtimeMinutes ?? 0;
    if (runtime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.runtimeNotAvailableForFilm)),
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
        SnackBar(content: Text(l10n.alreadyMarkedAsWatched)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedToCatalogue)),
    );
    _notifyWatchTimeChanged();
  }

  Future<void> _toggleFavorite() async {
    await _appServices.toggleFavorite(widget.item);
    if (!mounted) return;
    _notifyWatchTimeChanged();
  }

  Future<void> _toggleFollowed() async {
    await _appServices.toggleFollowed(widget.item.id);
    if (!mounted) return;
    _notifyWatchTimeChanged();
  }

  Future<void> _addEpisodeToCatalogue(EpisodeModel episode) async {
    final show = widget.item as TvShow;
    final l10n = context.l10n;
    final season = _loadedSeasons[episode.seasonNumber];
    final fallbackRuntime = _runtimeFallbackFor(episode, season: season);
    final isWatched =
        _appServices.isWatched(mediaId: show.id, episodeId: episode.id);

    if (isWatched) {
      if (_appServices.wouldRemoveLastCataloguedEpisodes(
        mediaId: show.id,
        episodeIds: [episode.id],
      )) {
        final confirmed = await confirmRemoveFromCatalogue(context, show);
        if (!confirmed || !mounted) return;

        await _appServices.removeFromCatalogue(show);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removedFromCatalogue)),
        );
        _notifyWatchTimeChanged();
        return;
      }

      await _appServices.unmarkEpisodeWatched(episode.id);
      _notifyWatchTimeChanged();
      return;
    }

    if (episode.isUpcoming) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.episodeHasNotAiredYet)),
      );
      return;
    }

    if (episode.isAiringSoon(fallbackRuntimeMinutes: fallbackRuntime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.episodeAiringSoon)),
      );
      return;
    }

    final record = await _appServices.addEpisodeToCatalogue(
      show: show,
      episode: episode,
      fallbackRuntimeMinutes: fallbackRuntime,
    );

    if (!mounted) return;

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.episodeRuntimeNotAvailable)),
      );
      return;
    }

    _notifyWatchTimeChanged();
  }

  Future<void> _toggleSeasonInCatalogue(int seasonNumber) async {
    final season = await _ensureSeasonLoaded(seasonNumber);
    if (season == null || !mounted) return;
    if (season.episodes.isEmpty || season.isUpcoming) return;

    final show = widget.item as TvShow;
    final l10n = context.l10n;
    final catalogueEpisodes = season.episodes
        .where(
          (episode) => episode.isCatalogueAddable(
            fallbackRuntimeMinutes: _runtimeFallbackFor(
              episode,
              season: season,
            ),
          ),
        )
        .toList(growable: false);
    if (catalogueEpisodes.isEmpty) return;

    final allInCatalogue = catalogueEpisodes.every(
      (episode) => _appServices.isWatched(
        mediaId: show.id,
        episodeId: episode.id,
      ),
    );

    if (allInCatalogue) {
      if (_appServices.wouldRemoveLastCataloguedEpisodes(
        mediaId: show.id,
        episodeIds: catalogueEpisodes.map((episode) => episode.id),
      )) {
        final confirmed = await confirmRemoveFromCatalogue(context, show);
        if (!confirmed || !mounted) return;

        await _appServices.removeFromCatalogue(show);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removedFromCatalogue)),
        );
        _notifyWatchTimeChanged();
        return;
      }

      await _appServices.removeSeasonFromCatalogue(
        episodes: catalogueEpisodes,
      );
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
        SnackBar(content: Text(l10n.episodeAiringSoon)),
      );
      return;
    }

    _notifyWatchTimeChanged();
  }

  void _toggleSeason(int seasonNumber) {
    // Tapping a season that failed to load retries instead of collapsing.
    final retry = _failedSeasons.contains(seasonNumber);
    setState(() {
      if (_expandedSeasons.contains(seasonNumber) && !retry) {
        _expandedSeasons.remove(seasonNumber);
      } else {
        _expandedSeasons.add(seasonNumber);
      }
    });
    if (_expandedSeasons.contains(seasonNumber)) {
      _ensureSeasonLoaded(seasonNumber);
    }
  }

  /// Re-evaluates the jump button once the current frame is laid out.
  void _scheduleJumpUpdate() {
    if (_jumpUpdateScheduled) return;
    _jumpUpdateScheduled = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _jumpUpdateScheduled = false;
        if (mounted) _jumpTarget.value = _computeJumpTarget();
      })
      // Notifications can arrive after a frame: make sure another one runs.
      ..ensureVisualUpdate();
  }

  /// Only the sheet's own vertical scroll matters, not the cast carousel.
  bool _onSheetScroll(ScrollNotification notification) {
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical) {
      _scheduleJumpUpdate();
    }
    return false;
  }

  bool _onSheetMetricsChanged(ScrollMetricsNotification notification) {
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical) {
      _scheduleJumpUpdate();
    }
    return false;
  }

  RenderBox? _viewportBox() {
    final box = _viewportKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  /// Bounds of [key]'s widget relative to [viewport]; null when unmounted.
  Rect? _rectIn(GlobalKey key, RenderBox viewport) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: viewport);
    return topLeft & box.size;
  }

  SeasonJumpTarget? _computeJumpTarget() {
    final viewport = _viewportBox();
    final controller = _sheetScrollController;
    if (viewport == null || controller == null || !controller.hasClients) {
      return null;
    }
    final spans = <SeasonJumpSpan>[];
    for (final seasonNumber in _expandedSeasons) {
      final anchors = _seasonAnchors[seasonNumber];
      if (anchors == null) continue;
      final first = _rectIn(anchors.firstEpisode, viewport);
      final latest = _rectIn(anchors.latestEpisode, viewport);
      if (first == null || latest == null) continue;
      spans.add(
        SeasonJumpSpan(
          seasonNumber: seasonNumber,
          firstTop: first.top,
          latestBottom: latest.bottom,
        ),
      );
    }
    final position = controller.position;
    return resolveSeasonJumpTarget(
      spans,
      viewportHeight: viewport.size.height,
      bottomInset: SeasonJumpButton.coveredHeight(context),
      scrolledToEnd: position.pixels >= position.maxScrollExtent - 0.5,
      currentSeason: _jumpTarget.value?.seasonNumber,
    );
  }

  /// Scrolls to the latest aired episode (kept above the button) or back to
  /// the season header, so its first episode shows right below it.
  void _jumpWithinSeason(SeasonJumpTarget target) {
    final viewport = _viewportBox();
    final controller = _sheetScrollController;
    final anchors = _seasonAnchors[target.seasonNumber];
    if (viewport == null ||
        controller == null ||
        !controller.hasClients ||
        anchors == null) {
      return;
    }
    final double delta;
    if (target.direction == SeasonJumpDirection.toLatest) {
      final latest = _rectIn(anchors.latestEpisode, viewport);
      if (latest == null) return;
      delta = latest.bottom -
          (viewport.size.height - SeasonJumpButton.coveredHeight(context));
    } else {
      final header = _rectIn(anchors.season, viewport);
      if (header == null) return;
      delta = header.top;
    }
    final position = controller.position;
    final offset = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      controller.jumpTo(offset);
    } else {
      controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details = _details;
    final posterPath = details?.posterPath ?? widget.item.posterPath;
    final posterUrl = ApiConstants.posterUrl(
      posterPath,
      size: ApiConstants.w342Image,
    );
    final isFilm = widget.item is Film;
    final inCatalogue = _appServices.isInCatalogue(widget.item);
    final isFavorite = _appServices.isFavorite(widget.item);
    final isFollowed = !isFilm && _appServices.isFollowed(widget.item.id);
    final filmWatched =
        isFilm && _appServices.isWatched(mediaId: widget.item.id);
    final ratingChipLabel =
        details != null ? _ratingChipLabel(details) : null;

    return DraggableScrollableSheet(
      initialChildSize: isFilm ? 0.55 : 0.75,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
        // Expanding or loading a season moves the anchors: re-measure.
        _scheduleJumpUpdate();
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            key: _viewportKey,
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollMetricsNotification>(
                onNotification: _onSheetMetricsChanged,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onSheetScroll,
                  child: _buildSheetList(
                    scrollController: scrollController,
                    details: details,
                    posterUrl: posterUrl,
                    isFilm: isFilm,
                    inCatalogue: inCatalogue,
                    isFavorite: isFavorite,
                    isFollowed: isFollowed,
                    filmWatched: filmWatched,
                    ratingChipLabel: ratingChipLabel,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: SeasonJumpButton.bottomMargin,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ValueListenableBuilder<SeasonJumpTarget?>(
                      valueListenable: _jumpTarget,
                      builder: (context, target, _) => SeasonJumpButton(
                        target: target,
                        onPressed: _jumpWithinSeason,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetList({
    required ScrollController scrollController,
    required MediaDetails? details,
    required String posterUrl,
    required bool isFilm,
    required bool inCatalogue,
    required bool isFavorite,
    required bool isFollowed,
    required bool filmWatched,
    required String? ratingChipLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    // Shows reserve room below the content so the last episode can always
    // scroll above the season jump button.
    final bottomPadding = isFilm
        ? 32.0
        : math.max(32.0, SeasonJumpButton.coveredHeight(context));
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding),
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
          const DetailSkeleton()
        else if (details != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: AppNetworkImage(
                    url: posterUrl,
                    logicalWidth: 100,
                    fallback: _posterFallback(context),
                  ),
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
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            // Content title — keep onSurface (section titles use primary).
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (ratingChipLabel != null)
                          Semantics(
                            label: l10n.ratingSemantics(ratingChipLabel),
                            child: ExcludeSemantics(
                              child: _MetaChip(
                                icon: Icons.star_rounded,
                                label: ratingChipLabel,
                              ),
                            ),
                          ),
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
                        if (details.formattedStatus != null)
                          _MetaChip(
                            icon: Icons.flag_outlined,
                            label: details.formattedStatus!,
                          ),
                        _MetaChip(
                          icon: details.isFilm
                              ? Icons.movie_filter
                              : Icons.tv,
                          label: details.isFilm
                              ? l10n.mediaTypeFilm
                              : l10n.mediaTypeShow,
                        ),
                      ],
                    ),
                    if (details.genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final genre
                              in details.genres.take(3))
                            _GenreChip(label: genre),
                        ],
                      ),
                    ],
                    if (!isFilm &&
                        _appServices
                                .watchedEpisodesCountFor(widget.item.id) >
                            0) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.episodesInCatalogue(
                          _appServices
                              .watchedEpisodesCountFor(widget.item.id),
                        ),
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
                onPressed: _guarded(_toggleFilmWatched),
                icon: Icon(
                  filmWatched
                      ? Icons.check_circle
                      : Icons.play_circle_outline,
                ),
                label: Text(
                  filmWatched ? l10n.watched : l10n.markAsWatched,
                ),
              ),
            ),
            if (filmWatched) ...[
              const SizedBox(height: 12),
              _buildFavoriteButton(isFavorite: isFavorite),
            ],
          ],
          if (!isFilm) ...[
            if (inCatalogue) ...[
              const SizedBox(height: 20),
              _buildFollowedButton(isFollowed: isFollowed),
              const SizedBox(height: 12),
              _buildFavoriteButton(isFavorite: isFavorite),
            ],
            const SizedBox(height: 24),
            _buildSeasonsSection(),
          ],
          if (details.director != null &&
              details.director!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionLabel(
              details.isFilm ? l10n.director : l10n.createdBy,
            ),
            const SizedBox(height: 4),
            Text(
              details.director!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (details.cast.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionLabel(l10n.cast),
            const SizedBox(height: 12),
            _buildCastCarousel(details.cast),
          ],
          if (details.overview != null &&
              details.overview!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionLabel(l10n.overview),
            const SizedBox(height: 4),
            Text(
              details.overview!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
            ),
          ],
          if (details.watchProviderNames.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionLabel(l10n.whereToWatch),
            const SizedBox(height: 8),
            Semantics(
              label: l10n.whereToWatchSemantics(
                details.watchProviderNames.join(', '),
              ),
              child: ExcludeSemantics(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final provider in details.watchProviderNames)
                      _GenreChip(label: provider),
                  ],
                ),
              ),
            ),
          ],
          if (details.networkNames.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionLabel(l10n.networks),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final network in details.networkNames)
                  _GenreChip(label: network),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFavoriteButton({required bool isFavorite}) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _guarded(_toggleFavorite),
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
        ),
        label: Text(
          isFavorite ? l10n.favorite : l10n.markAsFavorite,
        ),
      ),
    );
  }

  Widget _buildFollowedButton({required bool isFollowed}) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _guarded(_toggleFollowed),
        icon: Icon(
          isFollowed
              ? Icons.notifications_active
              : Icons.notifications_outlined,
        ),
        label: Text(
          isFollowed ? l10n.followed : l10n.markAsFollowed,
        ),
      ),
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
    // 120 for photo and spacing, the rest for up to four lines of text:
    // that part grows with the system text size instead of overflowing.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 120 + 78 * (textScale < 1 ? 1 : textScale),
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
              child: AppNetworkImage(
                url: profileUrl,
                logicalWidth: 88,
                fallback: _castAvatarFallback(context),
              ),
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n.episodes),
        const SizedBox(height: 8),
        if (_seasonSummaries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.noEpisodesFound,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          )
        else
          ..._seasonSummaries.map(_buildSeasonSection),
      ],
    );
  }

  Widget _buildSeasonSection(SeasonSummary summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final seasonNumber = summary.seasonNumber;
    final season = _loadedSeasons[seasonNumber];
    final isExpanded = _expandedSeasons.contains(seasonNumber);
    final isLoading = _seasonLoads.containsKey(seasonNumber);
    final loadFailed = _failedSeasons.contains(seasonNumber);

    // Exact figures once the episodes are loaded; before that, the counts
    // from the show payload and the local watch history.
    final int watchedInSeason;
    final int addableCount;
    final int episodeCount;
    final bool isUpcoming;
    final DateTime? airDate;
    if (season != null) {
      final catalogueEpisodes = season.episodes
          .where(
            (episode) => episode.isCatalogueAddable(
              fallbackRuntimeMinutes: _runtimeFallbackFor(
                episode,
                season: season,
              ),
            ),
          )
          .toList(growable: false);
      watchedInSeason = catalogueEpisodes
          .where(
            (episode) => _appServices.isWatched(
              mediaId: widget.item.id,
              episodeId: episode.id,
            ),
          )
          .length;
      addableCount = catalogueEpisodes.length;
      episodeCount = season.episodes.length;
      isUpcoming = season.isUpcoming;
      airDate = season.airDate;
    } else {
      watchedInSeason = _appServices
          .watchedEpisodesFor(widget.item.id)
          .where((record) => record.seasonNumber == seasonNumber)
          .length;
      addableCount = summary.episodeCount;
      episodeCount = summary.episodeCount;
      isUpcoming = summary.isUpcoming;
      airDate = summary.airDate;
    }
    final allInCatalogue = addableCount > 0 && watchedInSeason >= addableCount;
    final partialInCatalogue = watchedInSeason > 0 && !allInCatalogue;
    final canAddSeason = addableCount > 0 && !isUpcoming;

    final String subtitle;
    if (loadFailed) {
      subtitle = l10n.seasonLoadFailed;
    } else if (isUpcoming) {
      subtitle = airDate != null
          ? l10n.upcomingWithDate(_formatShortAirDate(airDate))
          : l10n.upcoming;
    } else if (watchedInSeason > 0) {
      subtitle = l10n.seasonProgressInCatalogue(watchedInSeason, addableCount);
    } else {
      subtitle = l10n.episodeCountLabel(episodeCount);
    }

    final anchors =
        _seasonAnchors.putIfAbsent(seasonNumber, _SeasonAnchors.new);
    final latestIndex =
        season != null ? latestAiredEpisodeIndex(season.episodes) : null;

    final card = Card(
      key: anchors.season,
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(
        children: [
          ListTile(
            onTap: () => _toggleSeason(seasonNumber),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    summary.isSpecials
                        ? l10n.seasonSpecials
                        : l10n.seasonLabel(seasonNumber),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (isUpcoming) ...[
                  const SizedBox(width: 8),
                  const _StatusBadge.upcoming(),
                ],
              ],
            ),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: allInCatalogue
                      ? l10n.removeSeasonFromCatalogue
                      : l10n.addSeasonToCatalogue,
                  icon: Icon(
                    allInCatalogue
                        ? Icons.bookmark
                        : partialInCatalogue
                            ? Icons.bookmark_add
                            : Icons.bookmark_add_outlined,
                    color: allInCatalogue || partialInCatalogue
                        ? colorScheme.primary
                        : null,
                  ),
                  onPressed: canAddSeason
                      ? _guarded(() => _toggleSeasonInCatalogue(seasonNumber))
                      : null,
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),
          if (isExpanded && season != null)
            for (final (index, episode) in season.episodes.indexed)
              _anchoredEpisode(
                anchors: anchors,
                isFirst: index == 0,
                // No aired episode: no anchor, so the jump button stays hidden.
                isLatest: index == latestIndex,
                child: _buildEpisodeTile(episode, season: season),
              )
          else if (isExpanded && isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
    return _SeasonJumpHighlight(
      seasonNumber: seasonNumber,
      jumpTarget: _jumpTarget,
      child: card,
    );
  }

  /// Tags the first and latest aired episode so the jump button can find
  /// them; one episode can carry both anchors.
  Widget _anchoredEpisode({
    required _SeasonAnchors anchors,
    required bool isFirst,
    required bool isLatest,
    required Widget child,
  }) {
    var tile = child;
    if (isLatest) tile = KeyedSubtree(key: anchors.latestEpisode, child: tile);
    if (isFirst) tile = KeyedSubtree(key: anchors.firstEpisode, child: tile);
    return tile;
  }

  int? _runtimeFallbackFor(
    EpisodeModel episode, {
    SeasonModel? season,
  }) {
    final showAverage = _details?.averageEpisodeRuntimeMinutes;
    if (showAverage != null && showAverage > 0) return showAverage;
    if (season == null) return null;
    return EpisodeModel.averagePositiveRuntimeMinutes(
      season.episodes,
      excludeEpisodeId: episode.id,
    );
  }

  Widget _buildEpisodeTile(
    EpisodeModel episode, {
    required SeasonModel season,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final fallbackRuntime = _runtimeFallbackFor(episode, season: season);
    final isWatched = _appServices.isWatched(
      mediaId: widget.item.id,
      episodeId: episode.id,
    );
    final isUpcoming = episode.isUpcoming;
    final isAiringSoon = episode.isAiringSoon(
      fallbackRuntimeMinutes: fallbackRuntime,
    );
    final addDisabled = isUpcoming || isAiringSoon;

    final String? subtitle;
    if (isUpcoming) {
      subtitle = episode.airDate != null
          ? l10n.upcomingWithDate(_formatShortAirDate(episode.airDate!))
          : l10n.upcoming;
    } else if (isAiringSoon) {
      subtitle = episode.airDate != null
          ? l10n.airingSoonWithDate(_formatShortAirDate(episode.airDate!))
          : l10n.airingSoon;
    } else {
      subtitle = null;
    }

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
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUpcoming) ...[
            const _StatusBadge.upcoming(),
            const SizedBox(width: 4),
          ] else if (isAiringSoon) ...[
            const _StatusBadge.airingSoon(),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: isUpcoming
                ? l10n.episodeHasNotAiredYet
                : isAiringSoon
                    ? l10n.episodeAiringSoon
                    : isWatched
                        ? l10n.removeFromCatalogue
                        : l10n.addEpisodeToCatalogue,
            icon: Icon(
              isWatched ? Icons.bookmark : Icons.bookmark_add_outlined,
              color: isWatched ? colorScheme.primary : null,
            ),
            onPressed: addDisabled
                ? null
                : _guarded(() => _addEpisodeToCatalogue(episode)),
          ),
        ],
      ),
    );
  }

  String? _ratingChipLabel(MediaDetails details) {
    final fromDetails = details.voteAverage;
    if (fromDetails != null && fromDetails != 0) {
      return fromDetails.toStringAsFixed(1);
    }
    final fromItem = widget.item.voteAverage;
    if (fromDetails == null && fromItem > 0) {
      return fromItem.toStringAsFixed(1);
    }
    return null;
  }

  String _formatShortAirDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
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

/// Outlines a season card in primary while the jump button targets it.
///
/// A 2dp outline reads as "selected", unlike the primary tint used for
/// "in catalogue". It rebuilds only the outline, not the card, and switches
/// instantly with reduced motion.
class _SeasonJumpHighlight extends StatelessWidget {
  final int seasonNumber;
  final ValueListenable<SeasonJumpTarget?> jumpTarget;
  final Widget child;

  const _SeasonJumpHighlight({
    required this.seasonNumber,
    required this.jumpTarget,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ValueListenableBuilder<SeasonJumpTarget?>(
      valueListenable: jumpTarget,
      child: child,
      builder: (context, target, card) {
        final active = target?.seasonNumber == seasonNumber;
        return AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          foregroundDecoration: BoxDecoration(
            // Same radius as the Material 3 card underneath.
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? primary : primary.withValues(alpha: 0),
              width: 2,
            ),
          ),
          child: card,
        );
      },
    );
  }
}

/// Widgets of one season measured by the jump button.
class _SeasonAnchors {
  /// Season card: "back to first" aligns its header with the top edge.
  final season = GlobalKey();
  final firstEpisode = GlobalKey();

  /// Latest aired episode: "jump to latest" stops here.
  final latestEpisode = GlobalKey();
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

class _GenreChip extends StatelessWidget {
  final String label;

  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge.upcoming() : _airingSoon = false;
  const _StatusBadge.airingSoon() : _airingSoon = true;

  final bool _airingSoon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _airingSoon ? l10n.airingSoon : l10n.upcoming,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
