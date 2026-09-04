/// Lightweight model for a single TV episode shown in detail views.
class EpisodeModel {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final int? runtimeMinutes;
  final DateTime? airDate;

  const EpisodeModel({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.runtimeMinutes,
    this.airDate,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as int,
      episodeNumber: json['episode_number'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      runtimeMinutes: json['runtime'] as int?,
      airDate: parseAirDate(json['air_date'] as String?),
    );
  }

  /// Whether this episode has already aired (air date today or earlier).
  bool get hasAired {
    if (airDate == null) return false;
    return !isAirDateUpcoming(airDate!);
  }

  /// Whether this episode is scheduled for a future air date.
  /// Missing dates are not treated as upcoming (incomplete TMDB data).
  bool get isUpcoming {
    if (airDate == null) return false;
    return isAirDateUpcoming(airDate!);
  }

  static DateTime? parseAirDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// True when [date] is strictly after today (date-only, local).
  static bool isAirDateUpcoming(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return _isAfterDate(
      date.year,
      date.month,
      date.day,
      today.year,
      today.month,
      today.day,
    );
  }

  /// Compares [a] vs [b] by season then episode number.
  /// Returns negative if [a] is earlier, positive if later, 0 if equal.
  static int compareBySeasonAndNumber(
    EpisodeModel a,
    int seasonNumber,
    int episodeNumber,
  ) {
    if (a.seasonNumber != seasonNumber) {
      return a.seasonNumber.compareTo(seasonNumber);
    }
    return a.episodeNumber.compareTo(episodeNumber);
  }

  static int compareEpisodes(EpisodeModel a, EpisodeModel b) {
    final seasonCompare = a.seasonNumber.compareTo(b.seasonNumber);
    if (seasonCompare != 0) return seasonCompare;
    return a.episodeNumber.compareTo(b.episodeNumber);
  }

  static bool _isAfterDate(
    int y1,
    int m1,
    int d1,
    int y2,
    int m2,
    int d2,
  ) {
    if (y1 != y2) return y1 > y2;
    if (m1 != m2) return m1 > m2;
    return d1 > d2;
  }

  String get seasonLabel => 'S$seasonNumber';

  String get episodeLabel => 'E$episodeNumber';

  String get codeLabel => '$seasonLabel $episodeLabel';

  String get displayTitle =>
      name.isNotEmpty ? name : 'Episode $episodeNumber';

  @override
  String toString() => 'Episode($codeLabel, $name)';
}
