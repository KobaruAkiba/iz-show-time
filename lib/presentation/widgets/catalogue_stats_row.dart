import 'package:flutter/material.dart';
import '../../core/utils/duration_format.dart';
import '../../l10n/l10n.dart';

/// Thin summary line: total watch time and catalogue size.
///
/// Shows only the title count when [hideWatchTime] is on. The type counters
/// live in the shared media-type chips, not here. The text wraps instead of
/// truncating, so the row grows with large text sizes.
class CatalogueStatsRow extends StatelessWidget {
  static const double _minHeight = 40;
  static const String _separator = ' · ';

  final int totalCount;
  final int watchTimeMinutes;
  final bool hideWatchTime;

  const CatalogueStatsRow({
    super.key,
    required this.totalCount,
    this.watchTimeMinutes = 0,
    this.hideWatchTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titles = l10n.statsCatalogueTitleCount(totalCount);
    final String label;
    final String text;
    final String spoken;
    if (hideWatchTime) {
      label = l10n.statsYourCatalogue;
      text = titles;
      spoken = titles;
    } else {
      final time = formatDurationMinutes(watchTimeMinutes, l10n: l10n);
      label = l10n.statsTotalWatchTime;
      text = '$time$_separator$titles';
      spoken = '$time, $titles';
    }

    // One node for screen readers, with the metric name the icon stands for.
    return Semantics(
      container: true,
      label: '$label, $spoken',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Row(
          children: [
            Icon(
              hideWatchTime
                  ? Icons.collections_bookmark_outlined
                  : Icons.schedule,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
