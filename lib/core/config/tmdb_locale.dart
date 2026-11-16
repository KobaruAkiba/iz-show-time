import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Language and region sent to TMDB, taken from the device settings.
///
/// The app UI itself is English only; this localizes titles, overviews,
/// genres, certifications and "where to watch".
abstract final class TmdbLocale {
  static const String fallbackLanguage = 'en-US';
  static const String fallbackRegion = 'US';

  @visibleForTesting
  static Locale? debugLocaleOverride;

  static Locale get _locale =>
      debugLocaleOverride ?? PlatformDispatcher.instance.locale;

  /// IETF language tag, e.g. `it-IT`.
  static String get language {
    final locale = _locale;
    final code = locale.languageCode;
    // "und" is what the platform reports when it has no locale.
    if (code.isEmpty || code == 'und') return fallbackLanguage;
    final country = locale.countryCode;
    return country == null || country.isEmpty ? code : '$code-$country';
  }

  /// ISO 3166-1 country code, e.g. `IT`.
  static String get region {
    final country = _locale.countryCode;
    return country == null || country.isEmpty
        ? fallbackRegion
        : country.toUpperCase();
  }
}
