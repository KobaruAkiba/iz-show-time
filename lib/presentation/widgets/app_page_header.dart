import 'package:flutter/material.dart';

/// Shared page header used across all main screens.
class AppPageHeader extends StatelessWidget {
  final List<Widget>? actions;

  const AppPageHeader({super.key, this.actions});

  static const title = 'Iz Show Time';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
