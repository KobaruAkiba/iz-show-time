import 'episode_model.dart';

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

  String get label =>
      seasonNumber == 1 ? 'Season 1' : 'Season $seasonNumber';

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
