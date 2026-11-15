import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image cached on disk and decoded at its display size.
///
/// TMDB images are immutable per URL, so a disk cache avoids downloading the
/// same posters on every launch. The cache is emptied with the periodic TMDB
/// data purge (see `AppServices.clearCacheData`).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.logicalWidth,
    this.fit = BoxFit.cover,
  });

  /// Empty when there is no image: [fallback] is shown.
  final String url;

  /// Shown without a URL and when loading fails.
  final Widget fallback;

  /// Display width in logical pixels; bounds the decoded bitmap.
  final double? logicalWidth;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return fallback;

    final width = logicalWidth;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: width == null
          ? null
          : (width * MediaQuery.devicePixelRatioOf(context)).round(),
      fadeInDuration: const Duration(milliseconds: 150),
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
