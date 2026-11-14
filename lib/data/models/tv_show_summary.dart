/// Base TMDB `tv/{id}` fields needed by the new-episode check.
class TvShowSummary {
  final int? numberOfSeasons;
  final String? posterPath;
  final int? averageEpisodeRuntimeMinutes;

  /// TMDB `last_episode_to_air`, when known.
  final ({int seasonNumber, int episodeNumber})? lastAiredEpisode;

  /// ISO date of TMDB `next_episode_to_air`, when known.
  final String? nextEpisodeAirDate;

  const TvShowSummary({
    this.numberOfSeasons,
    this.posterPath,
    this.averageEpisodeRuntimeMinutes,
    this.lastAiredEpisode,
    this.nextEpisodeAirDate,
  });

  factory TvShowSummary.fromTmdbJson(Map<String, dynamic> json) {
    final runTimes = (json['episode_run_time'] as List<dynamic>?)
            ?.whereType<num>()
            .map((value) => value.toInt())
            .where((value) => value > 0)
            .toList() ??
        const <int>[];

    return TvShowSummary(
      numberOfSeasons: (json['number_of_seasons'] as num?)?.toInt(),
      posterPath: json['poster_path'] as String?,
      averageEpisodeRuntimeMinutes: runTimes.isEmpty
          ? null
          : runTimes.reduce((a, b) => a + b) ~/ runTimes.length,
      lastAiredEpisode: _parseEpisodeRef(json['last_episode_to_air']),
      nextEpisodeAirDate: _parseAirDate(json['next_episode_to_air']),
    );
  }

  static ({int seasonNumber, int episodeNumber})? _parseEpisodeRef(
    Object? raw,
  ) {
    if (raw is! Map) return null;
    final season = raw['season_number'];
    final episode = raw['episode_number'];
    if (season is! num || episode is! num) return null;
    return (seasonNumber: season.toInt(), episodeNumber: episode.toInt());
  }

  static String? _parseAirDate(Object? raw) {
    if (raw is! Map) return null;
    final date = raw['air_date'];
    if (date is! String) return null;
    final trimmed = date.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
