/// Episode model representing individual TV show episodes
class EpisodeModel {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final DateTime? airDate;
  final int? runtimeMinutes;

  const EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtimeMinutes,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final airDateStr = json['air_date'] as String?;
    if (airDateStr != null && airDateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(airDateStr);
    }

    return EpisodeModel(
      id: json['id'] as int,
      episodeNumber: json['episode_number'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      airDate: parsedDate,
      runtimeMinutes: json['runtime'] as int?,
    );
  }

  @override
  String toString() => 'Episode(id: $id, ep: $episodeNumber)';
}
