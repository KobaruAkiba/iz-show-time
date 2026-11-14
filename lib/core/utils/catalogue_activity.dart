import '../../data/models/catalogue_item.dart';
import '../../data/models/new_episode_alert.dart';
import '../../data/models/watch_record.dart';

/// Latest [WatchRecord.watchedAt] per media key (film or any episode of a
/// show), see [mediaKeyOf].
///
/// In this app [WatchRecord.watchedAt] is set when an item is added to the
/// catalogue, so the map is "last catalogue activity" per title.
Map<String, DateTime> lastCatalogueActivityByMediaId(
  Iterable<WatchRecord> history,
) {
  final latest = <String, DateTime>{};
  for (final record in history) {
    final key = record.mediaKey;
    final previous = latest[key];
    if (previous == null || record.watchedAt.isAfter(previous)) {
      latest[key] = record.watchedAt;
    }
  }
  return latest;
}

/// Descending nullable dates; nulls sort last.
int compareNullableDateDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

/// Continue Watching: air date DESC, then last catalogue activity, then showId.
int compareContinueWatchingAlerts(
  NewEpisodeAlert a,
  NewEpisodeAlert b,
  Map<String, DateTime> lastActivityByMediaId,
) {
  final byAir = compareNullableDateDesc(a.airDate, b.airDate);
  if (byAir != 0) return byAir;

  final byActivity = compareNullableDateDesc(
    lastActivityByMediaId[mediaKeyOf(isFilm: false, id: a.showId)],
    lastActivityByMediaId[mediaKeyOf(isFilm: false, id: b.showId)],
  );
  if (byActivity != 0) return byActivity;

  return a.showId.compareTo(b.showId);
}

/// Catalogue default: last activity DESC, then title, then id.
int compareCatalogueByLastActivity(
  CatalogueItem a,
  CatalogueItem b,
  Map<String, DateTime> lastActivityByMediaId,
) {
  final byActivity = compareNullableDateDesc(
    lastActivityByMediaId[a.mediaKey],
    lastActivityByMediaId[b.mediaKey],
  );
  if (byActivity != 0) return byActivity;

  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  if (byTitle != 0) return byTitle;

  return a.id.compareTo(b.id);
}
