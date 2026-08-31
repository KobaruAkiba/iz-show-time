/// Film model representing movie data from TMDB
class FilmModel {
  final int id;
  final String title;
  final String originalTitle;
  final String? overview;
  final String? posterPath;
  final double voteAverage;
  final List<String> tags;

  const FilmModel({
    required this.id,
    required this.title,
    required this.originalTitle,
    this.overview,
    this.posterPath,
    this.voteAverage = 0.0,
    this.tags = const [],
  });

  @override
  String toString() => 'FilmModel(id: $id, title: $title)';
}
