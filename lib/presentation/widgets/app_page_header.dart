import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

/// Shared page header used across all main screens.
class AppPageHeader extends StatelessWidget {
  final List<Widget>? actions;

  const AppPageHeader({super.key, this.actions});

  static const _titleAsset = 'assets/images/IzShowTimeTitle.png';
  static const _tmdbIconAsset = 'assets/icons/TmdbIcon.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  _titleAsset,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (actions != null) ...actions!,
            Text(
              context.l10n.poweredByTmdb,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(width: 6),
            Image.asset(
              _tmdbIconAsset,
              height: 40,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
