import '../../data/models/watch_record.dart';

/// In-memory watch history with the lookups the UI needs on every build.
///
/// Holds state only: persistence stays with the caller, which batches disk
/// writes per user action.
class WatchHistoryIndex {
  final List<WatchRecord> _records = [];
  final Set<int> _watchedEpisodeIds = {};
  final Set<int> _watchedFilmIds = {};
  final Map<int, int> _episodeCountByShowId = {};

  List<WatchRecord> get records => List.unmodifiable(_records);

  int get totalMinutes =>
      _records.fold(0, (sum, record) => sum + record.durationMinutes);

  int get filmCount => _watchedFilmIds.length;

  int get episodeCount => _watchedEpisodeIds.length;

  /// Episode ids are unique across shows, so [mediaId] only matters for films.
  bool isWatched({required int mediaId, int? episodeId}) {
    if (episodeId != null) return _watchedEpisodeIds.contains(episodeId);
    return _watchedFilmIds.contains(mediaId);
  }

  bool isEpisodeWatched(int episodeId) =>
      _watchedEpisodeIds.contains(episodeId);

  int episodeCountFor(int showId) => _episodeCountByShowId[showId] ?? 0;

  List<WatchRecord> episodesFor(int showId) => _records
      .where((record) => !record.isFilm && record.mediaId == showId)
      .toList(growable: false);

  void replaceAll(Iterable<WatchRecord> records) {
    clear();
    for (final record in records) {
      add(record);
    }
  }

  void add(WatchRecord record) {
    _records.add(record);
    if (record.isFilm) {
      _watchedFilmIds.add(record.mediaId);
      return;
    }
    final episodeId = record.episodeId;
    if (episodeId == null) return;
    if (_watchedEpisodeIds.add(episodeId)) {
      _episodeCountByShowId.update(
        record.mediaId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  void removeAll(List<WatchRecord> records) {
    if (records.isEmpty) return;
    final keys = {for (final record in records) record.watchKey};
    _records.removeWhere((record) => keys.contains(record.watchKey));
    for (final record in records) {
      _unindex(record);
    }
  }

  void clear() {
    _records.clear();
    _watchedEpisodeIds.clear();
    _watchedFilmIds.clear();
    _episodeCountByShowId.clear();
  }

  void _unindex(WatchRecord record) {
    if (record.isFilm) {
      _watchedFilmIds.remove(record.mediaId);
      return;
    }
    final episodeId = record.episodeId;
    if (episodeId == null) return;
    if (!_watchedEpisodeIds.remove(episodeId)) return;
    final remaining = (_episodeCountByShowId[record.mediaId] ?? 1) - 1;
    if (remaining <= 0) {
      _episodeCountByShowId.remove(record.mediaId);
    } else {
      _episodeCountByShowId[record.mediaId] = remaining;
    }
  }
}
