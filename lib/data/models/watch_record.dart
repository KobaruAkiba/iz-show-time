/// A single watched film or TV episode entry used to accumulate watch time.
class WatchRecord {
  final int mediaId;
  final String mediaTitle;
  final bool isFilm;
  final int? episodeId;
  final int? seasonNumber;
  final int? episodeNumber;
  final int durationMinutes;
  final DateTime watchedAt;

  const WatchRecord({
    required this.mediaId,
    required this.mediaTitle,
    required this.isFilm,
    this.episodeId,
    this.seasonNumber,
    this.episodeNumber,
    required this.durationMinutes,
    required this.watchedAt,
  });

  /// Unique key to prevent counting the same film or episode twice.
  String get watchKey =>
      isFilm ? 'film_$mediaId' : 'episode_${episodeId ?? '$mediaId-$seasonNumber-$episodeNumber'}';

  Map<String, dynamic> toJson() => {
        'media_id': mediaId,
        'media_title': mediaTitle,
        'is_film': isFilm,
        'episode_id': episodeId,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'duration_minutes': durationMinutes,
        'watched_at': watchedAt.toIso8601String(),
      };

  factory WatchRecord.fromJson(Map<String, dynamic> json) {
    return WatchRecord(
      mediaId: json['media_id'] as int,
      mediaTitle: json['media_title'] as String? ?? '',
      isFilm: json['is_film'] as bool? ?? true,
      episodeId: json['episode_id'] as int?,
      seasonNumber: json['season_number'] as int?,
      episodeNumber: json['episode_number'] as int?,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      watchedAt: DateTime.tryParse(json['watched_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  String toString() =>
      'WatchRecord($watchKey, ${durationMinutes}m)';
}
