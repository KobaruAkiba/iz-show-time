import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Makes sure a list that overflows the viewport can scroll its headers away.
///
/// A floating header can only hide completely once the scroll offset passes
/// the header itself. With a short list the maximum scroll offset stops
/// before that, leaving the header half hidden with nothing to snap it. When
/// the content overflows, this sliver extends the scrollable area to at least
/// one viewport after the headers. Content that fits is left untouched, so it
/// does not become scrollable.
class SliverScrollableFloor extends SingleChildRenderObjectWidget {
  const SliverScrollableFloor({super.key, required Widget sliver})
      : super(child: sliver);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverScrollableFloor();
}

class _RenderSliverScrollableFloor extends RenderProxySliver {
  @override
  void performLayout() {
    super.performLayout();
    final childGeometry = geometry!;
    final viewport = constraints.viewportMainAxisExtent;
    final overflows =
        constraints.precedingScrollExtent + childGeometry.scrollExtent >
            viewport;
    if (overflows && childGeometry.scrollExtent < viewport) {
      geometry = childGeometry.copyWith(scrollExtent: viewport);
    }
  }
}
