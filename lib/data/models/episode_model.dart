/// Episode model representing individual TV show episodes

class EpisodeModel {
  final int id;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final DateTime airDate = DateTime(2024, 1, 1);

  EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
  });

  @override
  String toString() => 'Episode(id: $id, ep: $episodeNumber)';
}
