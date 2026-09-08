// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IzShowTime';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navCatalogue => 'Catalogue';

  @override
  String get navSettings => 'Settings';

  @override
  String get poweredByTmdb => 'powered by TMDb';

  @override
  String get searchEllipsis => 'Search...';

  @override
  String get ratingUnavailable => 'N/A';

  @override
  String get mediaTypeFilm => 'Film';

  @override
  String get mediaTypeShow => 'Show';

  @override
  String episodeCountBadge(int count) {
    return '$count ep';
  }

  @override
  String get episodeCountBadgeOne => '1 ep';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get tapForDetails => 'Tap for details';

  @override
  String get statsShows => 'Shows';

  @override
  String get statsFilms => 'Films';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsTotalWatchTime => 'Total Watch Time';

  @override
  String get filterAll => 'All';

  @override
  String get filterFilms => 'Films';

  @override
  String get filterTv => 'Shows';

  @override
  String get sortDefault => 'Default order';

  @override
  String get sortTitleAsc => 'Title (A → Z)';

  @override
  String get sortTitleDesc => 'Title (Z → A)';

  @override
  String get sortRatingDesc => 'Rating (high → low)';

  @override
  String get sortRatingAsc => 'Rating (low → high)';

  @override
  String get filtersAndSort => 'Filters & Sort';

  @override
  String get filtersShowSection => 'Show';

  @override
  String get filtersStatusSection => 'Status';

  @override
  String get filtersFavorites => 'Favorites';

  @override
  String get filtersInProgress => 'In Progress';

  @override
  String get filtersInProgressHint =>
      'Shows still airing or with an upcoming episode.';

  @override
  String get filtersSortBy => 'Sort by';

  @override
  String get filtersReset => 'Reset';

  @override
  String get filtersApply => 'Apply';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get actionOpen => 'Open';

  @override
  String get confirmRemoveFromCatalogueTitle => 'Remove from Catalogue';

  @override
  String confirmRemoveFilmBody(String title) {
    return 'Remove \"$title\" from your catalogue?\n\nWatch history for this title will be deleted.';
  }

  @override
  String confirmRemoveShowBody(String title) {
    return 'Remove \"$title\" from your catalogue?\n\nAll watched episodes will be deleted.';
  }

  @override
  String get addedToCatalogue => 'Added to catalogue';

  @override
  String get removedFromCatalogue => 'Removed from catalogue';

  @override
  String get runtimeNotAvailableForFilm => 'Runtime unavailable for this film';

  @override
  String get alreadyMarkedAsWatched => 'Already marked as watched';

  @override
  String get episodeHasNotAiredYet => 'This episode hasn\'t aired yet';

  @override
  String get episodeRuntimeNotAvailable => 'Episode runtime unavailable';

  @override
  String get cacheClearedSuccessfully => 'Cache cleared';

  @override
  String get allDataClearedSuccessfully => 'All data cleared';

  @override
  String get watched => 'Watched';

  @override
  String get markAsWatched => 'Mark as Watched';

  @override
  String get favorite => 'Favorite';

  @override
  String get markAsFavorite => 'Mark as Favorite';

  @override
  String get followed => 'Followed';

  @override
  String get markAsFollowed => 'Follow show';

  @override
  String get addToFollowed => 'Follow show';

  @override
  String get removeFromFollowed => 'Unfollow show';

  @override
  String get director => 'Director';

  @override
  String get createdBy => 'Created by';

  @override
  String get cast => 'Cast';

  @override
  String get overview => 'Overview';

  @override
  String get networks => 'Networks';

  @override
  String get statusReturningSeries => 'Returning Series';

  @override
  String get statusPlanned => 'Planned';

  @override
  String get statusInProduction => 'In Production';

  @override
  String get statusEnded => 'Ended';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusPilot => 'Pilot';

  @override
  String get episodes => 'Episodes';

  @override
  String get noEpisodesFound => 'No episodes found';

  @override
  String get upcoming => 'Upcoming';

  @override
  String upcomingWithDate(String date) {
    return 'Upcoming · $date';
  }

  @override
  String episodesInCatalogue(int count) {
    return '$count episode(s) in catalogue';
  }

  @override
  String seasonProgressInCatalogue(int watched, int total) {
    return '$watched / $total in catalogue';
  }

  @override
  String episodeCountLabel(int count) {
    return '$count episodes';
  }

  @override
  String get addSeasonToCatalogue => 'Add season to catalogue';

  @override
  String get removeSeasonFromCatalogue => 'Remove season from catalogue';

  @override
  String get addEpisodeToCatalogue => 'Add episode to catalogue';

  @override
  String get removeFromCatalogue => 'Remove from catalogue';

  @override
  String seasonLabel(int number) {
    return 'Season $number';
  }

  @override
  String episodeFallbackTitle(int number) {
    return 'Episode $number';
  }

  @override
  String seasonCode(int number) {
    return 'S$number';
  }

  @override
  String episodeCode(int number) {
    return 'E$number';
  }

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String runtimeHoursOnly(int hours) {
    return '${hours}h';
  }

  @override
  String runtimeMinutesOnly(int minutes) {
    return '${minutes}m';
  }

  @override
  String get seasonsCountOne => '1 season';

  @override
  String seasonsCountOther(int count) {
    return '$count seasons';
  }

  @override
  String get durationZeroMinutes => '0m';

  @override
  String durationYears(int count) {
    return '${count}y';
  }

  @override
  String durationMonths(int count) {
    return '${count}M';
  }

  @override
  String durationDays(int count) {
    return '${count}d';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String get hoursOnlyHintOne => 'that\'s 1 hour';

  @override
  String hoursOnlyHintOther(int hours) {
    return 'that\'s $hours hours';
  }

  @override
  String get homeTrendingLoadFailed =>
      'Couldn\'t load trending. Check your connection and try again.';

  @override
  String get homeNoTrending =>
      'No trending titles right now. Check your TMDb API key.';

  @override
  String get homeTrendingNow => 'Trending Now';

  @override
  String get homeTrendingSubtitle => 'Swipe to browse · tap for details';

  @override
  String get homeNewEpisodes => 'Continue Watching';

  @override
  String get homeNewEpisodesSubtitle =>
      'Next up after your last watched episode';

  @override
  String get homeNewEpisodesEmptyTitle => 'Nothing here yet';

  @override
  String get homeNewEpisodesEmptyBody =>
      'Add a show and mark an episode watched. The next one will show up here.';

  @override
  String get homeNewEpisodesCaughtUpTitle => 'All caught up';

  @override
  String get homeNewEpisodesCaughtUpBody =>
      'You\'re up to date on shows in your catalogue.';

  @override
  String homeAiredOn(String date) {
    return 'Aired $date';
  }

  @override
  String get searchHint => 'Search films and shows...';

  @override
  String get searchAction => 'Search';

  @override
  String get searchFailed =>
      'Search couldn\'t finish. Check your connection and try again.';

  @override
  String get searchNoFilterMatches => 'No results match your filters';

  @override
  String searchNoResultsForQuery(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String searchResultsCount(String count) {
    return '$count results';
  }

  @override
  String searchFilteredOfTotal(int filtered, int total) {
    return '$filtered of $total';
  }

  @override
  String get searchEmptyTitle => 'Search for films and shows';

  @override
  String get searchEmptySubtitle => 'Type a title to get started';

  @override
  String get catalogueSearchHint => 'Search catalogue...';

  @override
  String get catalogueEmpty => 'Your catalogue is empty';

  @override
  String get catalogueNoFilterMatches => 'No results match your filters';

  @override
  String get catalogueNoFavorites =>
      'No favorites yet.\nTap the heart on any title to add one.';

  @override
  String get catalogueNoInProgress =>
      'No shows in progress.\nStill-airing series or those with an upcoming episode appear here.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsCredits => 'Credits';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAuthor => 'Author';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsSupportMe => 'Support me';

  @override
  String get settingsSupportMeDescription =>
      'Donations are voluntary and help cover hosting, tools, and app store costs. Thank you.';

  @override
  String get settingsDonatePaypal => 'Donate with ';

  @override
  String get settingsDonatePaypalError =>
      'Couldn\'t open PayPal. Try again later.';

  @override
  String get settingsDataManagement => 'Data Management';

  @override
  String get settingsClearCacheTitle => 'Clear Cache';

  @override
  String get settingsClearCacheSubtitle =>
      'Free space. Catalogue and watch history stay.';

  @override
  String get settingsClearCacheBody =>
      'This removes cached API data to free space.\n\nYour catalogue and watch history are kept.';

  @override
  String get settingsClearCacheConfirm => 'Clear Cache';

  @override
  String get settingsClearAllTitle => 'Clear All Data';

  @override
  String get settingsClearAllSubtitle =>
      'Remove catalogue, watch history, and cached data';

  @override
  String get settingsClearAllBody =>
      'This permanently deletes your catalogue, watch history, and cached data.\n\nThis can\'t be undone.';

  @override
  String get settingsClearAllConfirm => 'Delete All Data';

  @override
  String get settingsTmdbAttribution =>
      'Data and images from The Movie Database';

  @override
  String get settingsTmdbDisclaimer =>
      'This product uses TMDb and the TMDb APIs but is not endorsed, certified, or otherwise approved by TMDb.';

  @override
  String get settingsTmdbLinkError =>
      'Couldn\'t open The Movie Database. Try again later.';

  @override
  String get notificationChannelName => 'New Episodes';

  @override
  String get notificationChannelDescription =>
      'Alerts when new TV episodes air';

  @override
  String get notificationTitle => 'New episodes available';

  @override
  String get notificationBodyOne =>
      'A new episode is waiting. Check Continue Watching on Home.';

  @override
  String notificationBodyOther(int count) {
    return '$count new episodes available. Check Continue Watching on Home.';
  }

  @override
  String get notificationPermissionTitle => 'Episode alerts';

  @override
  String get notificationPermissionBody =>
      'Optional — the app works without them. When on, IzShowTime alerts you when a new episode airs for a show you follow.';

  @override
  String get notificationPermissionNotNow => 'Not now';

  @override
  String get notificationPermissionContinue => 'Continue';

  @override
  String get errorTooManyRequests =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorResourceNotFound => 'Couldn\'t find that title.';

  @override
  String get errorAccessDenied => 'Access denied. Check your API key.';

  @override
  String get errorInvalidResponse => 'Got an unexpected response. Try again.';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorNoConnection =>
      'You\'re offline. Check Wi‑Fi or mobile data, then try again.';

  @override
  String get errorTimeout =>
      'Request timed out. Check your network and try again.';

  @override
  String get errorUnreachable =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get connectionNoNetworkTitle => 'No connection';

  @override
  String get connectionTimeoutTitle => 'Request timed out';

  @override
  String get connectionUnreachableTitle => 'Can\'t reach the server';

  @override
  String get connectionSlowTitle => 'Still connecting';

  @override
  String get connectionSlow =>
      'Still connecting… this is taking longer than usual.';
}
