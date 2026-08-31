/// TV Show model representing series data from TMDB
class TvShowModel {
  final int id;
  final String name;
  final String originalName;
  final String? overview;
  final String? posterPath;
  final double voteAverage;
  final List<String> tags;

  const TvShowModel({
    required this.id,
    required this.name,
    required this.originalName,
    this.overview,
    this.posterPath,
    this.voteAverage = 0.0,
    this.tags = const [],
  });

  @override
  String toString() => 'TvShowModel(id: $id, name: $name)';
}
