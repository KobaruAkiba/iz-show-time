import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Enables mouse drag scrolling on web/desktop (PageView, ListView, etc.).
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse,
      };
}
