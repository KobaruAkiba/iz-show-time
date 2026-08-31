/// Base class for all catalogue items (Films and TV Shows)
abstract class CatalogueItem {
  final int id;
  final String title;
  final List<String> tags;

  const CatalogueItem({
    required this.id,
    required this.title,
    this.tags = const [],
  });
}

/// Extension to add common functionality to catalogue items
extension CatalogueItemExtension on CatalogueItem {
  bool containsTag(String tag) {
    return tags.contains(tag);
  }
  
  List<String> withoutTag(String tag) {
    return tags.where((t) => t != tag).toList();
  }
}

/// Film catalogue item extending base model
class Film extends CatalogueItem {
  final String? overview;
  final String? posterPath;
  final double voteAverage;

  const Film({
    required super.id,
    required super.title,
    this.overview,
    this.posterPath,
    this.voteAverage = 0.0,
    super.tags = const [],
  });

  @override
  String toString() => 'Film(id: $id, title: $title)';
}

/// TV Show catalogue item extending base model
class TvShow extends CatalogueItem {
  final int seasonNumber;
  final int episodeNumber;
  final String? overview;
  final String? posterPath;
  final double voteAverage;

  const TvShow({
    required super.id,
    required super.title,
    required this.seasonNumber,
    required this.episodeNumber,
    this.overview,
    this.posterPath,
    this.voteAverage = 0.0,
    super.tags = const [],
  });

  @override
  String toString() => 'TvShow(id: $id, name: $title)';
}
