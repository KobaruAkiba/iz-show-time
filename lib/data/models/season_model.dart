import '../../l10n/l10n.dart';
import 'episode_model.dart';

/// Season entry of the TMDB show payload (`seasons[]`): enough to list a
/// season before its episodes are loaded.
class SeasonSummary {
  final int seasonNumber;
  final int episodeCount;
  final DateTime? airDate;

  const SeasonSummary({
    required this.seasonNumber,
    this.episodeCount = 0,
    this.airDate,
  });

  /// TMDB numbers specials as season 0.
  bool get isSpecials => seasonNumber == 0;

  /// Judged from the show payload alone: no episodes, or a future air date.
  bool get isUpcoming {
    if (episodeCount <= 0) return true;
    final date = airDate;
    return date != null && EpisodeModel.isAirDateUpcoming(date);
  }

  /// Regular seasons in order, specials last. Empty specials are dropped.
  static List<SeasonSummary> listFromTmdbJson(Object? raw) {
    if (raw is! List) return const [];
    final summaries = <SeasonSummary>[
      for (final entry in raw)
        if (entry is Map && entry['season_number'] is num)
          SeasonSummary(
            seasonNumber: (entry['season_number'] as num).toInt(),
            episodeCount: (entry['episode_count'] as num?)?.toInt() ?? 0,
            airDate: EpisodeModel.parseAirDate(entry['air_date'] as String?),
          ),
    ]..removeWhere((season) => season.isSpecials && season.episodeCount <= 0);
    int rank(SeasonSummary season) =>
        season.isSpecials ? 1 << 30 : season.seasonNumber;
    summaries.sort((a, b) => rank(a).compareTo(rank(b)));
    return summaries;
  }
}

/// A TV season with its episodes, used in detail views.
class SeasonModel {
  final int seasonNumber;
  final DateTime? airDate;
  final List<EpisodeModel> episodes;

  const SeasonModel({
    required this.seasonNumber,
    this.airDate,
    required this.episodes,
  });

  factory SeasonModel.fromTmdbSeasonJson(Map<String, dynamic> json) {
    final rawEpisodes = json['episodes'] as List<dynamic>? ?? const [];
    return SeasonModel(
      seasonNumber: json['season_number'] as int? ?? 0,
      airDate: EpisodeModel.parseAirDate(json['air_date'] as String?),
      episodes: rawEpisodes
          .whereType<Map<String, dynamic>>()
          .map(EpisodeModel.fromJson)
          .toList(),
    );
  }

  String get label => AppL10n.current.seasonLabel(seasonNumber);

  /// True when the season has not started airing yet:
  /// empty placeholder seasons, or seasons where nothing has aired and
  /// either episode/season air dates point to the future, or TMDB only
  /// returned unnamed stub episodes.
  bool get isUpcoming {
    if (episodes.any((episode) => episode.hasAired)) return false;
    if (episodes.isEmpty) return true;
    if (episodes.any((episode) => episode.isUpcoming)) return true;
    if (airDate != null && EpisodeModel.isAirDateUpcoming(airDate!)) {
      return true;
    }
    return episodes.every(
      (episode) => episode.name.trim().isEmpty && episode.airDate == null,
    );
  }
}
