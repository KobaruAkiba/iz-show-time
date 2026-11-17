import 'package:flutter/material.dart';

/// Hosts the snackbars of a modal bottom sheet above the sheet itself.
///
/// Without it, `ScaffoldMessenger.of` inside the sheet reaches the page
/// scaffold, whose snackbars sit behind the modal route. The transparent
/// layer under [child] keeps "tap outside to close" working, since the
/// scaffold would otherwise swallow those taps.
class SheetSnackBarHost extends StatelessWidget {
  const SheetSnackBarHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // The route barrier already announces "Dismiss" to screen readers.
            Positioned.fill(
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
