import 'package:flutter/material.dart';

/// Sliver holding the type filter, the search field and the active chips.
///
/// It disappears when the list scrolls down and comes back as soon as the user
/// scrolls up, even mid-list (Material 3 "floating" app bar behaviour). It
/// sizes itself to its content, so wrapping chips or large text just work.
/// Place it after the parts of the header that scroll away.
class FloatingSearchHeader extends StatelessWidget {
  /// Shown above [search], e.g. the type filter chips.
  final Widget? leading;

  /// Usually a [MediaSearchField].
  final Widget search;

  /// Chips shown under the search field, or null when none are active.
  final Widget? chips;

  const FloatingSearchHeader({
    super.key,
    this.leading,
    required this.search,
    this.chips,
  });

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
              if (leading != null) ...[
                leading!,
                const SizedBox(height: 8),
              ],
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
