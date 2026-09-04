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
  String get ratingUnavailable => 'N/D';

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
  String get filtersAndSort => 'Filters & sort';

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
      'Shows with the next episode already aired and not yet registered.';

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
  String get actionOpen => 'Open';

  @override
  String get confirmRemoveFromCatalogueTitle => 'Remove from Catalogue';

  @override
  String confirmRemoveFilmBody(String title) {
    return 'Remove the film \"$title\" from your catalogue?\n\nWatch history for this title will be permanently deleted.';
  }

  @override
  String confirmRemoveShowBody(String title) {
    return 'Remove the show \"$title\" from your catalogue?\n\nAll watched episodes will be permanently deleted from your watch history.';
  }

  @override
  String get addedToCatalogue => 'Added to catalogue';

  @override
  String get removedFromCatalogue => 'Removed from catalogue';

  @override
  String get runtimeNotAvailableForFilm =>
      'Runtime not available for this film';

  @override
  String get alreadyMarkedAsWatched => 'Already marked as watched';

  @override
  String get episodeHasNotAiredYet => 'Episode has not aired yet';

  @override
  String get episodeRuntimeNotAvailable => 'Episode runtime not available';

  @override
  String get cacheClearedSuccessfully => 'Cache data cleared successfully';

  @override
  String get allDataClearedSuccessfully => 'All data cleared successfully';

  @override
  String get watched => 'Watched';

  @override
  String get markAsWatched => 'Mark as Watched';

  @override
  String get favorite => 'Favorite';

  @override
  String get markAsFavorite => 'Mark as Favorite';

  @override
  String get director => 'Director';

  @override
  String get createdBy => 'Created by';

  @override
  String get cast => 'Cast';

  @override
  String get overview => 'Overview';

  @override
  String get episodes => 'Episodes';

  @override
  String get noEpisodesFound => 'No episodes found.';

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
  String get homeTrendingLoadFailed => 'Failed to load trending content';

  @override
  String get homeNoTrending =>
      'No trending content available. Check your TMDB API key.';

  @override
  String get homeTrendingNow => 'Trending Now';

  @override
  String get homeTrendingSubtitle => 'Swipe to explore · tap for details';

  @override
  String get homeNewEpisodes => 'New Episodes';

  @override
  String get homeNewEpisodesSubtitle =>
      'The next episode to watch after your last registered one';

  @override
  String get homeNewEpisodesEmptyTitle => 'Nothing here yet';

  @override
  String get homeNewEpisodesEmptyBody =>
      'Register an episode in your catalogue and the next one in order will appear here.';

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
      'Search failed. Check your API key and connection.';

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
  String get searchEmptySubtitle =>
      'Type a title and press Enter or the search button';

  @override
  String get catalogueSearchHint => 'Search catalogue...';

  @override
  String get catalogueEmpty => 'Your catalogue is empty';

  @override
  String get catalogueNoFilterMatches => 'No results match your filters';

  @override
  String get catalogueNoFavorites =>
      'No favorites yet.\nTap the heart on a catalogue item to mark it as favorite.';

  @override
  String get catalogueNoInProgress =>
      'No shows currently in progress.\nRegister an episode, then when the next one airs it will show up here.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsDataManagement => 'Data Management';

  @override
  String get settingsClearCacheTitle => 'Clear Cache Data';

  @override
  String get settingsClearCacheSubtitle =>
      'Free space by removing cached API responses. Catalogue and watch history are kept';

  @override
  String get settingsClearCacheBody =>
      'This will remove cached API responses to free space on your device.\n\nYour catalogue and watch history will not be deleted.';

  @override
  String get settingsClearCacheConfirm => 'Clear Cache';

  @override
  String get settingsClearAllTitle => 'Clear All Data';

  @override
  String get settingsClearAllSubtitle =>
      'Remove catalogue, watch history, and cached data';

  @override
  String get settingsClearAllBody =>
      'This will permanently delete your catalogue, watch history, and cached data.\n\nYour data cannot be recovered after this action.';

  @override
  String get settingsClearAllConfirm => 'Delete All Data';

  @override
  String get settingsTmdbAttribution =>
      'Data and images provided from The Movie Database';

  @override
  String get settingsTmdbDisclaimer =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get notificationChannelName => 'New Episodes';

  @override
  String get notificationChannelDescription =>
      'Alerts when new TV episodes are detected';

  @override
  String get notificationTitle => 'New episodes available';

  @override
  String get notificationBodyOne =>
      'A new episode is waiting in your catalogue. Open Home and check New Episodes.';

  @override
  String notificationBodyOther(int count) {
    return '$count new episodes are available. Open Home and check New Episodes.';
  }

  @override
  String get errorTooManyRequests => 'Too many requests. Please wait a moment.';

  @override
  String get errorResourceNotFound => 'Resource not found.';

  @override
  String get errorAccessDenied => 'Access denied. API key may be invalid.';

  @override
  String get errorInvalidResponse => 'Invalid response from server.';

  @override
  String get errorGeneric => 'An error occurred';
}
