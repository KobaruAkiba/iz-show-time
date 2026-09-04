import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Convenience accessors for generated [AppLocalizations].
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Locale-aware lookup for code paths without a [BuildContext]
/// (notifications, models, formatters). Defaults to English until a locale
/// is loaded from the widget tree.
abstract final class AppL10n {
  static Locale _locale = const Locale('en');

  static void updateLocale(Locale locale) {
    _locale = locale;
  }

  static AppLocalizations get current => lookupAppLocalizations(_locale);
}
