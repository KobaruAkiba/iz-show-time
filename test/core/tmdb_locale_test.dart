import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/config/tmdb_locale.dart';

void main() {
  tearDown(() => TmdbLocale.debugLocaleOverride = null);

  test('uses the device language and country', () {
    TmdbLocale.debugLocaleOverride = const Locale('it', 'IT');

    expect(TmdbLocale.language, 'it-IT');
    expect(TmdbLocale.region, 'IT');
  });

  test('sends the bare language and the default region without a country',
      () {
    TmdbLocale.debugLocaleOverride = const Locale('fr');

    expect(TmdbLocale.language, 'fr');
    expect(TmdbLocale.region, TmdbLocale.fallbackRegion);
  });

  test('falls back to English when the platform has no locale', () {
    TmdbLocale.debugLocaleOverride = const Locale('und');

    expect(TmdbLocale.language, TmdbLocale.fallbackLanguage);
    expect(TmdbLocale.region, TmdbLocale.fallbackRegion);
  });
}
