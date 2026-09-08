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
  /// **'N/A'**
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
  /// **'Filters & Sort'**
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
  /// **'Shows still airing or with an upcoming episode.'**
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

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

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
  /// **'Remove \"{title}\" from your catalogue?\n\nWatch history for this title will be deleted.'**
  String confirmRemoveFilmBody(String title);

  /// No description provided for @confirmRemoveShowBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from your catalogue?\n\nAll watched episodes will be deleted.'**
  String confirmRemoveShowBody(String title);

  /// No description provided for @addedToCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Added to catalogue'**
  String get addedToCatalogue;

  /// No description provided for @removedFromCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Removed from catalogue'**
  String get removedFromCatalogue;

  /// No description provided for @runtimeNotAvailableForFilm.
  ///
  /// In en, this message translates to:
  /// **'Runtime unavailable for this film'**
  String get runtimeNotAvailableForFilm;

  /// No description provided for @alreadyMarkedAsWatched.
  ///
  /// In en, this message translates to:
  /// **'Already marked as watched'**
  String get alreadyMarkedAsWatched;

  /// No description provided for @episodeHasNotAiredYet.
  ///
  /// In en, this message translates to:
  /// **'This episode hasn\'t aired yet'**
  String get episodeHasNotAiredYet;

  /// No description provided for @episodeRuntimeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Episode runtime unavailable'**
  String get episodeRuntimeNotAvailable;

  /// No description provided for @cacheClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheClearedSuccessfully;

  /// No description provided for @allDataClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
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

  /// No description provided for @followed.
  ///
  /// In en, this message translates to:
  /// **'Followed'**
  String get followed;

  /// No description provided for @markAsFollowed.
  ///
  /// In en, this message translates to:
  /// **'Follow show'**
  String get markAsFollowed;

  /// No description provided for @addToFollowed.
  ///
  /// In en, this message translates to:
  /// **'Follow show'**
  String get addToFollowed;

  /// No description provided for @removeFromFollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollow show'**
  String get removeFromFollowed;

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

  /// No description provided for @networks.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get networks;

  /// No description provided for @statusReturningSeries.
  ///
  /// In en, this message translates to:
  /// **'Returning Series'**
  String get statusReturningSeries;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @statusInProduction.
  ///
  /// In en, this message translates to:
  /// **'In Production'**
  String get statusInProduction;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @statusPilot.
  ///
  /// In en, this message translates to:
  /// **'Pilot'**
  String get statusPilot;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @noEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes found'**
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
  /// **'{count} episodes in catalogue'**
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
  /// **'Couldn\'t load trending. Check your connection and try again.'**
  String get homeTrendingLoadFailed;

  /// No description provided for @homeNoTrending.
  ///
  /// In en, this message translates to:
  /// **'No trending titles right now. Check your TMDb API key.'**
  String get homeNoTrending;

  /// No description provided for @homeTrendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get homeTrendingNow;

  /// No description provided for @homeTrendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to browse · tap for details'**
  String get homeTrendingSubtitle;

  /// No description provided for @homeNewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get homeNewEpisodes;

  /// No description provided for @homeNewEpisodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next up after your last watched episode'**
  String get homeNewEpisodesSubtitle;

  /// No description provided for @homeNewEpisodesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get homeNewEpisodesEmptyTitle;

  /// No description provided for @homeNewEpisodesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a show and mark an episode watched. The next one will show up here.'**
  String get homeNewEpisodesEmptyBody;

  /// No description provided for @homeNewEpisodesCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get homeNewEpisodesCaughtUpTitle;

  /// No description provided for @homeNewEpisodesCaughtUpBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date on shows in your catalogue.'**
  String get homeNewEpisodesCaughtUpBody;

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
  /// **'Search couldn\'t finish. Check your connection and try again.'**
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
  /// **'Type a title to get started'**
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
  /// **'No favorites yet.\nTap the heart on any title to add one.'**
  String get catalogueNoFavorites;

  /// No description provided for @catalogueNoInProgress.
  ///
  /// In en, this message translates to:
  /// **'No shows in progress.\nStill-airing series or those with an upcoming episode appear here.'**
  String get catalogueNoInProgress;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get settingsCredits;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get settingsAuthor;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsSupportMe.
  ///
  /// In en, this message translates to:
  /// **'Support me'**
  String get settingsSupportMe;

  /// No description provided for @settingsSupportMeDescription.
  ///
  /// In en, this message translates to:
  /// **'Donations are voluntary and help cover hosting, tools, and app store costs. Thank you.'**
  String get settingsSupportMeDescription;

  /// No description provided for @settingsDonatePaypal.
  ///
  /// In en, this message translates to:
  /// **'Donate with '**
  String get settingsDonatePaypal;

  /// No description provided for @settingsDonatePaypalError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open PayPal. Try again later.'**
  String get settingsDonatePaypalError;

  /// No description provided for @settingsDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsDataManagement;

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free space. Catalogue and watch history stay.'**
  String get settingsClearCacheSubtitle;

  /// No description provided for @settingsClearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'This removes cached API data to free space.\n\nYour catalogue and watch history are kept.'**
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
  /// **'This permanently deletes your catalogue, watch history, and cached data.\n\nThis can\'t be undone.'**
  String get settingsClearAllBody;

  /// No description provided for @settingsClearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get settingsClearAllConfirm;

  /// No description provided for @settingsTmdbAttribution.
  ///
  /// In en, this message translates to:
  /// **'Data and images from The Movie Database'**
  String get settingsTmdbAttribution;

  /// No description provided for @settingsTmdbDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This product uses TMDb and the TMDb APIs but is not endorsed, certified, or otherwise approved by TMDb.'**
  String get settingsTmdbDisclaimer;

  /// No description provided for @settingsTmdbLinkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open The Movie Database. Try again later.'**
  String get settingsTmdbLinkError;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'New Episodes'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Alerts when new TV episodes air'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New episodes available'**
  String get notificationTitle;

  /// No description provided for @notificationBodyOne.
  ///
  /// In en, this message translates to:
  /// **'A new episode is waiting. Check Continue Watching on Home.'**
  String get notificationBodyOne;

  /// No description provided for @notificationBodyOther.
  ///
  /// In en, this message translates to:
  /// **'{count} new episodes available. Check Continue Watching on Home.'**
  String notificationBodyOther(int count);

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Episode alerts'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Optional — the app works without them. When on, IzShowTime alerts you when a new episode airs for a show you follow.'**
  String get notificationPermissionBody;

  /// No description provided for @notificationPermissionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notificationPermissionNotNow;

  /// No description provided for @notificationPermissionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get notificationPermissionContinue;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Wait a moment and try again.'**
  String get errorTooManyRequests;

  /// No description provided for @errorResourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that title.'**
  String get errorResourceNotFound;

  /// No description provided for @errorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Check your API key.'**
  String get errorAccessDenied;

  /// No description provided for @errorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Got an unexpected response. Try again.'**
  String get errorInvalidResponse;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check Wi‑Fi or mobile data, then try again.'**
  String get errorNoConnection;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Check your network and try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get errorUnreachable;

  /// No description provided for @connectionNoNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get connectionNoNetworkTitle;

  /// No description provided for @connectionTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get connectionTimeoutTitle;

  /// No description provided for @connectionUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server'**
  String get connectionUnreachableTitle;

  /// No description provided for @connectionSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Still connecting'**
  String get connectionSlowTitle;

  /// No description provided for @connectionSlow.
  ///
  /// In en, this message translates to:
  /// **'Still connecting… this is taking longer than usual.'**
  String get connectionSlow;
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
