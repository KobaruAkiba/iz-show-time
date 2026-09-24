import '../../l10n/l10n.dart';

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

  /// Duration used for catalogue add (episode runtime or show-level fallback).
  int resolvedRuntimeMinutes({int? fallbackRuntimeMinutes}) =>
      runtimeMinutes ?? fallbackRuntimeMinutes ?? 0;

  /// Whether a positive duration can be resolved for catalogue / watch time.
  bool hasCatalogueRuntime({int? fallbackRuntimeMinutes}) =>
      resolvedRuntimeMinutes(fallbackRuntimeMinutes: fallbackRuntimeMinutes) >
      0;

  /// Catalogue-addable: not future-dated, and duration resolvable.
  /// Undated episodes with runtime stay addable.
  bool isCatalogueAddable({int? fallbackRuntimeMinutes, DateTime? now}) {
    return isCatalogueAddableFields(
      airDate: airDate,
      runtimeMinutes: runtimeMinutes,
      fallbackRuntimeMinutes: fallbackRuntimeMinutes,
      now: now,
    );
  }

  /// Visible in the list, not upcoming, but cannot be added (missing runtime).
  bool isAiringSoon({int? fallbackRuntimeMinutes, DateTime? now}) {
    if (isAirDateUpcomingField(airDate, now: now)) return false;
    return !hasCatalogueRuntime(fallbackRuntimeMinutes: fallbackRuntimeMinutes);
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

  /// True when [airDate] is present and strictly after today.
  /// Missing dates are not treated as upcoming.
  static bool isAirDateUpcomingField(DateTime? airDate, {DateTime? now}) {
    if (airDate == null) return false;
    return isAirDateUpcoming(airDate, now: now);
  }

  /// True when [date] falls on the same local calendar day as [now].
  static bool isSameCalendarDay(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// True when [airDate] is today's local calendar day (TMDB air date).
  static bool isAiredToday(DateTime? airDate, {DateTime? now}) {
    if (airDate == null) return false;
    return isSameCalendarDay(airDate, now: now);
  }

  /// Catalogue-addable from alert / loose fields (same rules as [isCatalogueAddable]).
  static bool isCatalogueAddableFields({
    required DateTime? airDate,
    required int? runtimeMinutes,
    int? fallbackRuntimeMinutes,
    DateTime? now,
  }) {
    if (isAirDateUpcomingField(airDate, now: now)) return false;
    final duration = runtimeMinutes ?? fallbackRuntimeMinutes ?? 0;
    return duration > 0;
  }

  /// Average of positive runtimes in [episodes], optionally skipping one id.
  /// Used as catalogue fallback when TMDB omits runtime on a single episode.
  static int? averagePositiveRuntimeMinutes(
    Iterable<EpisodeModel> episodes, {
    int? excludeEpisodeId,
  }) {
    var sum = 0;
    var count = 0;
    for (final episode in episodes) {
      if (excludeEpisodeId != null && episode.id == excludeEpisodeId) {
        continue;
      }
      final runtime = episode.runtimeMinutes;
      if (runtime == null || runtime <= 0) continue;
      sum += runtime;
      count++;
    }
    if (count == 0) return null;
    return sum ~/ count;
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
    return compareBySeasonAndNumber(a, b.seasonNumber, b.episodeNumber);
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

  String get seasonLabel => AppL10n.current.seasonCode(seasonNumber);

  String get episodeLabel => AppL10n.current.episodeCode(episodeNumber);

  String get codeLabel => '$seasonLabel $episodeLabel';

  String get displayTitle => name.isNotEmpty
      ? name
      : AppL10n.current.episodeFallbackTitle(episodeNumber);

  @override
  String toString() => 'Episode($codeLabel, $name)';
}
