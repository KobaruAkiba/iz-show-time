/// Lightweight model for a single TV episode shown in detail views.
class EpisodeModel {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final int? runtimeMinutes;

  const EpisodeModel({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.runtimeMinutes,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as int,
      episodeNumber: json['episode_number'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      runtimeMinutes: json['runtime'] as int?,
    );
  }

  String get seasonLabel => 'S$seasonNumber';

  String get episodeLabel => 'E$episodeNumber';

  String get codeLabel => '$seasonLabel $episodeLabel';

  String get displayTitle =>
      name.isNotEmpty ? name : 'Episode $episodeNumber';

  @override
  String toString() => 'Episode($codeLabel, $name)';
}
