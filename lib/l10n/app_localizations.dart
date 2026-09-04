import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'IzShowTime'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get navCatalogue;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @poweredByTmdb.
  ///
  /// In en, this message translates to:
  /// **'powered by TMDb'**
  String get poweredByTmdb;

  /// No description provided for @searchEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchEllipsis;

  /// No description provided for @ratingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'N/D'**
  String get ratingUnavailable;

  /// No description provided for @mediaTypeFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get mediaTypeFilm;

  /// No description provided for @mediaTypeShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get mediaTypeShow;

  /// No description provided for @episodeCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} ep'**
  String episodeCountBadge(int count);

  /// No description provided for @episodeCountBadgeOne.
  ///
  /// In en, this message translates to:
  /// **'1 ep'**
  String get episodeCountBadgeOne;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @tapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get tapForDetails;

  /// No description provided for @statsShows.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get statsShows;

  /// No description provided for @statsFilms.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get statsFilms;

  /// No description provided for @statsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statsTotal;

  /// No description provided for @statsTotalWatchTime.
  ///
  /// In en, this message translates to:
  /// **'Total Watch Time'**
  String get statsTotalWatchTime;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterFilms.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get filterFilms;

  /// No description provided for @filterTv.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get filterTv;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default order'**
  String get sortDefault;

  /// No description provided for @sortTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title (A → Z)'**
  String get sortTitleAsc;

  /// No description provided for @sortTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Title (Z → A)'**
  String get sortTitleDesc;

  /// No description provided for @sortRatingDesc.
  ///
  /// In en, this message translates to:
  /// **'Rating (high → low)'**
  String get sortRatingDesc;

  /// No description provided for @sortRatingAsc.
  ///
  /// In en, this message translates to:
  /// **'Rating (low → high)'**
  String get sortRatingAsc;

  /// No description provided for @filtersAndSort.
  ///
  /// In en, this message translates to:
  /// **'Filters & sort'**
  String get filtersAndSort;

  /// No description provided for @filtersShowSection.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get filtersShowSection;

  /// No description provided for @filtersStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filtersStatusSection;

  /// No description provided for @filtersFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get filtersFavorites;

  /// No description provided for @filtersInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filtersInProgress;

  /// No description provided for @filtersInProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Shows with the next episode already aired and not yet registered.'**
  String get filtersInProgressHint;

  /// No description provided for @filtersSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filtersSortBy;

  /// No description provided for @filtersReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filtersReset;

  /// No description provided for @filtersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filtersApply;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @confirmRemoveFromCatalogueTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Catalogue'**
  String get confirmRemoveFromCatalogueTitle;

  /// No description provided for @confirmRemoveFilmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the film \"{title}\" from your catalogue?\n\nWatch history for this title will be permanently deleted.'**
  String confirmRemoveFilmBody(String title);

  /// No description provided for @confirmRemoveShowBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the show \"{title}\" from your catalogue?\n\nAll watched episodes will be permanently deleted from your watch history.'**
  String confirmRemoveShowBody(String title);

  /// No description provided for @addedToCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Aggiunto a catalogo'**
  String get addedToCatalogue;

  /// No description provided for @removedFromCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Rimosso da catalogo'**
  String get removedFromCatalogue;

  /// No description provided for @runtimeNotAvailableForFilm.
  ///
  /// In en, this message translates to:
  /// **'Runtime not available for this film'**
  String get runtimeNotAvailableForFilm;

  /// No description provided for @alreadyMarkedAsWatched.
  ///
  /// In en, this message translates to:
  /// **'Already marked as watched'**
  String get alreadyMarkedAsWatched;

  /// No description provided for @episodeHasNotAiredYet.
  ///
  /// In en, this message translates to:
  /// **'Episode has not aired yet'**
  String get episodeHasNotAiredYet;

  /// No description provided for @episodeRuntimeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Episode runtime not available'**
  String get episodeRuntimeNotAvailable;

  /// No description provided for @cacheClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cache data cleared successfully'**
  String get cacheClearedSuccessfully;

  /// No description provided for @allDataClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All data cleared successfully'**
  String get allDataClearedSuccessfully;

  /// No description provided for @watched.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get watched;

  /// No description provided for @markAsWatched.
  ///
  /// In en, this message translates to:
  /// **'Mark as Watched'**
  String get markAsWatched;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @markAsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark as Favorite'**
  String get markAsFavorite;

  /// No description provided for @director.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get director;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @cast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get cast;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @noEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes found.'**
  String get noEpisodesFound;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @upcomingWithDate.
  ///
  /// In en, this message translates to:
  /// **'Upcoming · {date}'**
  String upcomingWithDate(String date);

  /// No description provided for @episodesInCatalogue.
  ///
  /// In en, this message translates to:
  /// **'{count} episode(s) in catalogue'**
  String episodesInCatalogue(int count);

  /// No description provided for @seasonProgressInCatalogue.
  ///
  /// In en, this message translates to:
  /// **'{watched} / {total} in catalogue'**
  String seasonProgressInCatalogue(int watched, int total);

  /// No description provided for @episodeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} episodes'**
  String episodeCountLabel(int count);

  /// No description provided for @addSeasonToCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Add season to catalogue'**
  String get addSeasonToCatalogue;

  /// No description provided for @removeSeasonFromCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Remove season from catalogue'**
  String get removeSeasonFromCatalogue;

  /// No description provided for @addEpisodeToCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Add episode to catalogue'**
  String get addEpisodeToCatalogue;

  /// No description provided for @removeFromCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Remove from catalogue'**
  String get removeFromCatalogue;

  /// No description provided for @seasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonLabel(int number);

  /// No description provided for @episodeFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String episodeFallbackTitle(int number);

  /// No description provided for @seasonCode.
  ///
  /// In en, this message translates to:
  /// **'S{number}'**
  String seasonCode(int number);

  /// No description provided for @episodeCode.
  ///
  /// In en, this message translates to:
  /// **'E{number}'**
  String episodeCode(int number);

  /// No description provided for @runtimeHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String runtimeHoursMinutes(int hours, int minutes);

  /// No description provided for @runtimeHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String runtimeHoursOnly(int hours);

  /// No description provided for @runtimeMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String runtimeMinutesOnly(int minutes);

  /// No description provided for @seasonsCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 season'**
  String get seasonsCountOne;

  /// No description provided for @seasonsCountOther.
  ///
  /// In en, this message translates to:
  /// **'{count} seasons'**
  String seasonsCountOther(int count);

  /// No description provided for @durationZeroMinutes.
  ///
  /// In en, this message translates to:
  /// **'0m'**
  String get durationZeroMinutes;

  /// No description provided for @durationYears.
  ///
  /// In en, this message translates to:
  /// **'{count}y'**
  String durationYears(int count);

  /// No description provided for @durationMonths.
  ///
  /// In en, this message translates to:
  /// **'{count}M'**
  String durationMonths(int count);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String durationDays(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String durationHours(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String durationMinutes(int count);

  /// No description provided for @hoursOnlyHintOne.
  ///
  /// In en, this message translates to:
  /// **'that\'s 1 hour'**
  String get hoursOnlyHintOne;

  /// No description provided for @hoursOnlyHintOther.
  ///
  /// In en, this message translates to:
  /// **'that\'s {hours} hours'**
  String hoursOnlyHintOther(int hours);

  /// No description provided for @homeTrendingLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trending content'**
  String get homeTrendingLoadFailed;

  /// No description provided for @homeNoTrending.
  ///
  /// In en, this message translates to:
  /// **'No trending content available. Check your TMDB API key.'**
  String get homeNoTrending;

  /// No description provided for @homeTrendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get homeTrendingNow;

  /// No description provided for @homeTrendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to explore · tap for details'**
  String get homeTrendingSubtitle;

  /// No description provided for @homeNewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'New Episodes'**
  String get homeNewEpisodes;

  /// No description provided for @homeNewEpisodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The next episode to watch after your last registered one'**
  String get homeNewEpisodesSubtitle;

  /// No description provided for @homeNewEpisodesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get homeNewEpisodesEmptyTitle;

  /// No description provided for @homeNewEpisodesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Register an episode in your catalogue and the next one in order will appear here.'**
  String get homeNewEpisodesEmptyBody;

  /// No description provided for @homeAiredOn.
  ///
  /// In en, this message translates to:
  /// **'Aired {date}'**
  String homeAiredOn(String date);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search films and shows...'**
  String get searchHint;

  /// No description provided for @searchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your API key and connection.'**
  String get searchFailed;

  /// No description provided for @searchNoFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'No results match your filters'**
  String get searchNoFilterMatches;

  /// No description provided for @searchNoResultsForQuery.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResultsForQuery(String query);

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String searchResultsCount(String count);

  /// No description provided for @searchFilteredOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total}'**
  String searchFilteredOfTotal(int filtered, int total);

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search for films and shows'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type a title and press Enter or the search button'**
  String get searchEmptySubtitle;

  /// No description provided for @catalogueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search catalogue...'**
  String get catalogueSearchHint;

  /// No description provided for @catalogueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your catalogue is empty'**
  String get catalogueEmpty;

  /// No description provided for @catalogueNoFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'No results match your filters'**
  String get catalogueNoFilterMatches;

  /// No description provided for @catalogueNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.\nTap the heart on a catalogue item to mark it as favorite.'**
  String get catalogueNoFavorites;

  /// No description provided for @catalogueNoInProgress.
  ///
  /// In en, this message translates to:
  /// **'No shows currently in progress.\nRegister an episode, then when the next one airs it will show up here.'**
  String get catalogueNoInProgress;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsDataManagement;

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache Data'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free space by removing cached API responses. Catalogue and watch history are kept'**
  String get settingsClearCacheSubtitle;

  /// No description provided for @settingsClearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove cached API responses to free space on your device.\n\nYour catalogue and watch history will not be deleted.'**
  String get settingsClearCacheBody;

  /// No description provided for @settingsClearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCacheConfirm;

  /// No description provided for @settingsClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get settingsClearAllTitle;

  /// No description provided for @settingsClearAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove catalogue, watch history, and cached data'**
  String get settingsClearAllSubtitle;

  /// No description provided for @settingsClearAllBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your catalogue, watch history, and cached data.\n\nYour data cannot be recovered after this action.'**
  String get settingsClearAllBody;

  /// No description provided for @settingsClearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get settingsClearAllConfirm;

  /// No description provided for @settingsTmdbAttribution.
  ///
  /// In en, this message translates to:
  /// **'Data and images provided from The Movie Database'**
  String get settingsTmdbAttribution;

  /// No description provided for @settingsTmdbDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get settingsTmdbDisclaimer;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'New Episodes'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Alerts when new TV episodes are detected'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New episodes available'**
  String get notificationTitle;

  /// No description provided for @notificationBodyOne.
  ///
  /// In en, this message translates to:
  /// **'A new episode is waiting in your catalogue. Open Home and check New Episodes.'**
  String get notificationBodyOne;

  /// No description provided for @notificationBodyOther.
  ///
  /// In en, this message translates to:
  /// **'{count} new episodes are available. Open Home and check New Episodes.'**
  String notificationBodyOther(int count);

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get errorTooManyRequests;

  /// No description provided for @errorResourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get errorResourceNotFound;

  /// No description provided for @errorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. API key may be invalid.'**
  String get errorAccessDenied;

  /// No description provided for @errorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response from server.'**
  String get errorInvalidResponse;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
