import 'package:flutter/material.dart';

/// Sliver holding the search field and the active filter chips.
///
/// It disappears when the list scrolls down and comes back as soon as the user
/// scrolls up, even mid-list (Material 3 "floating" app bar behaviour). It
/// sizes itself to its content, so wrapping chips or large text just work.
/// Place it after the parts of the header that scroll away.
class FloatingSearchHeader extends StatelessWidget {
  /// Usually a [MediaSearchField].
  final Widget search;

  /// Chips shown under the search field, or null when none are active.
  final Widget? chips;

  const FloatingSearchHeader({super.key, required this.search, this.chips});

  @override
  Widget build(BuildContext context) {
    return SliverFloatingHeader(
      child: ColoredBox(
        // Opaque, because the header overlays the list while it floats.
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              if (chips != null) ...[
                const SizedBox(height: 8),
                chips!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
