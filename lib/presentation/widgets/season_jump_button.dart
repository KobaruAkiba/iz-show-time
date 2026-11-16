import 'package:flutter/material.dart';

import '../../data/models/episode_model.dart';
import '../../l10n/l10n.dart';

/// Where the season jump button scrolls to.
enum SeasonJumpDirection { toLatest, toFirst }

/// The season the jump button acts on, and in which direction.
@immutable
class SeasonJumpTarget {
  final int seasonNumber;
  final SeasonJumpDirection direction;

  const SeasonJumpTarget({
    required this.seasonNumber,
    required this.direction,
  });

  @override
  bool operator ==(Object other) =>
      other is SeasonJumpTarget &&
      other.seasonNumber == seasonNumber &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(seasonNumber, direction);
}

/// Vertical extent of one expanded season's episodes, in viewport
/// coordinates (0 = top edge of the scrolling area).
@immutable
class SeasonJumpSpan {
  final int seasonNumber;

  /// Top edge of the season's first episode.
  final double firstTop;

  /// Bottom edge of the season's latest aired episode.
  final double latestBottom;

  const SeasonJumpSpan({
    required this.seasonNumber,
    required this.firstTop,
    required this.latestBottom,
  });
}

/// Index of the latest episode already aired, or null when none has.
///
/// Episodes without an air date are usually TMDB placeholders at the end of
/// the list: they count only when no dated episode has aired.
int? latestAiredEpisodeIndex(List<EpisodeModel> episodes) {
  int? undatedFallback;
  for (var i = episodes.length - 1; i >= 0; i--) {
    final episode = episodes[i];
    if (episode.isUpcoming) continue;
    if (episode.airDate != null) return i;
    undatedFallback ??= i;
  }
  return undatedFallback;
}

/// Visible height a season must gain over the active one to take over.
const double seasonJumpSwitchMargin = 48;

/// Picks the season and direction for the jump button; null hides it.
///
/// Rules:
/// 1. Seasons whose episodes fit above [bottomInset] are ignored.
/// 2. Among the rest, the one with the largest visible part is active.
///    [currentSeason] stays active until another season shows at least
///    [seasonJumpSwitchMargin] more: slow scrolling between two expanded
///    seasons does not flip the button back and forth.
/// 3. Latest episode below the usable area → [SeasonJumpDirection.toLatest].
/// 4. Otherwise, first episode above the top edge →
///    [SeasonJumpDirection.toFirst].
///
/// [bottomInset] is the strip covered by the button itself.
/// [scrolledToEnd] stops offering a jump the list can no longer perform.
SeasonJumpTarget? resolveSeasonJumpTarget(
  Iterable<SeasonJumpSpan> spans, {
  required double viewportHeight,
  required double bottomInset,
  bool scrolledToEnd = false,
  int? currentSeason,
}) {
  const tolerance = 1.0;
  final usableBottom = viewportHeight - bottomInset;
  if (usableBottom <= 0) return null;

  SeasonJumpSpan? active;
  SeasonJumpSpan? current;
  var bestVisible = 0.0;
  var currentVisible = 0.0;
  for (final span in spans) {
    if (span.latestBottom - span.firstTop <= usableBottom) continue;
    final visible = (span.latestBottom.clamp(0.0, viewportHeight)) -
        (span.firstTop.clamp(0.0, viewportHeight));
    if (visible <= 0) continue;
    if (span.seasonNumber == currentSeason) {
      current = span;
      currentVisible = visible;
    }
    if (visible > bestVisible) {
      bestVisible = visible;
      active = span;
    }
  }
  if (current != null &&
      bestVisible < currentVisible + seasonJumpSwitchMargin) {
    active = current;
  }
  if (active == null) return null;

  if (!scrolledToEnd && active.latestBottom > usableBottom + tolerance) {
    return SeasonJumpTarget(
      seasonNumber: active.seasonNumber,
      direction: SeasonJumpDirection.toLatest,
    );
  }
  if (active.firstTop < -tolerance) {
    return SeasonJumpTarget(
      seasonNumber: active.seasonNumber,
      direction: SeasonJumpDirection.toFirst,
    );
  }
  return null;
}

/// Floating pill that jumps to the latest aired episode of a long season,
/// or back to its first episode.
///
/// The label names the season ("S3 · Jump to latest"), so the target is
/// clear even when the season header is off screen.
/// Fades and slides in and out; with reduced motion it appears instantly.
class SeasonJumpButton extends StatelessWidget {
  /// Null hides the button.
  final SeasonJumpTarget? target;

  final ValueChanged<SeasonJumpTarget> onPressed;

  const SeasonJumpButton({
    super.key,
    required this.target,
    required this.onPressed,
  });

  /// Vertical space the button covers, from the bottom of the sheet.
  static double coveredHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + bottomMargin + 56 + 8;

  static const double bottomMargin = 16;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final current = target;

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: current == null
          ? const SizedBox.shrink(key: ValueKey('season-jump-hidden'))
          : _buildPill(context, current),
    );
  }

  Widget _buildPill(BuildContext context, SeasonJumpTarget current) {
    final l10n = context.l10n;
    final toLatest = current.direction == SeasonJumpDirection.toLatest;
    final isSpecials = current.seasonNumber == 0;
    final shortSeason = isSpecials
        ? l10n.seasonSpecials
        : l10n.seasonShortLabel(current.seasonNumber);
    final fullSeason = isSpecials
        ? l10n.seasonSpecials
        : l10n.seasonLabel(current.seasonNumber);

    // Visible label abbreviates the season; screen readers get it in full.
    return Semantics(
      key: ValueKey(current),
      button: true,
      label: toLatest
          ? l10n.jumpToLatestEpisodeSemantics(fullSeason)
          : l10n.backToFirstEpisodeSemantics(fullSeason),
      onTap: () => onPressed(current),
      excludeSemantics: true,
      child: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => onPressed(current),
        icon: Icon(toLatest ? Icons.arrow_downward : Icons.arrow_upward),
        label: Text(
          toLatest
              ? l10n.jumpToLatestEpisode(shortSeason)
              : l10n.backToFirstEpisode(shortSeason),
        ),
      ),
    );
  }
}
