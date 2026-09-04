import '../../core/constants/api_constants.dart';

/// Reserved catalogue tag for user favorites.
const String kFavoriteTag = 'favorite';

/// Base class for all catalogue items (Films and Shows)
abstract class CatalogueItem {
  final int id;
  final String title;
  final List<String> tags;

  const CatalogueItem({
    required this.id,
    required this.title,
    this.tags = const [],
  });

  String? get posterPath;
  double get voteAverage;
  String? get overview;
  String get posterUrl => ApiConstants.posterUrl(posterPath);

  CatalogueItem copyWithTags(List<String> newTags);
}

extension CatalogueItemExtension on CatalogueItem {
  bool containsTag(String tag) => tags.contains(tag);

  List<String> withoutTag(String tag) => tags.where((t) => t != tag).toList();

  bool get isFavorite => containsTag(kFavoriteTag);

  CatalogueItem withFavorite(bool favorite) {
    if (favorite == isFavorite) return this;
    if (favorite) return copyWithTags([...tags, kFavoriteTag]);
    return copyWithTags(withoutTag(kFavoriteTag));
  }

  bool get isFilm => this is Film;
  bool get isTvShow => this is TvShow;
}

/// Film catalogue item
class Film extends CatalogueItem {
  @override
  final String? overview;
  @override
  final String? posterPath;
  @override
  final double voteAverage;

  const Film({
    required super.id,
    required super.title,
    this.overview,
    this.posterPath,
    this.voteAverage = 0.0,
    super.tags = const [],
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['id'] as int,
      title: json['title'] as String? ??
          json['original_title'] as String? ??
          json['name'] as String? ??
          '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      tags: _parseTags(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'vote_average': voteAverage,
        'tags': tags,
      };

  @override
  Film copyWithTags(List<String> newTags) => Film(
        id: id,
        title: title,
        overview: overview,
        posterPath: posterPath,
        voteAverage: voteAverage,
        tags: newTags,
      );

  @override
  String toString() => 'Film(id: $id, title: $title)';
}

/// TV Show catalogue item — always represents the full series, not a single episode.
class TvShow extends CatalogueItem {
  @override
  final String? overview;
  @override
  final String? posterPath;
  @override
  final double voteAverage;

  const TvShow({
    required super.id,
    required super.title,
    this.overview,
    this.posterPath,
    this.voteAverage = 0.0,
    super.tags = const [],
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      id: json['id'] as int,
      title: json['name'] as String? ??
          json['original_name'] as String? ??
          json['title'] as String? ??
          '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      tags: _parseTags(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': title,
        'overview': overview,
        'poster_path': posterPath,
        'vote_average': voteAverage,
        'tags': tags,
      };

  @override
  TvShow copyWithTags(List<String> newTags) => TvShow(
        id: id,
        title: title,
        overview: overview,
        posterPath: posterPath,
        voteAverage: voteAverage,
        tags: newTags,
      );

  @override
  String toString() => 'TvShow(id: $id, name: $title)';
}

List<String> _parseTags(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((entry) => entry.toString()).toList(growable: false);
}

/// Serializes a catalogue item for local storage with a type discriminator.
Map<String, dynamic> catalogueItemToStorageJson(CatalogueItem item) {
  final payload = switch (item) {
    Film film => film.toJson(),
    TvShow show => show.toJson(),
    _ => throw ArgumentError(
        'Unsupported catalogue item type: ${item.runtimeType}'),
  };
  return {
    'type': item is Film ? 'film' : 'tv',
    ...payload,
  };
}

/// Restores a catalogue item from local storage JSON.
CatalogueItem? catalogueItemFromStorageJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'film':
      return Film.fromJson(json);
    case 'tv':
      return TvShow.fromJson(json);
    default:
      return null;
  }
}

/// Parse TMDB multi-search result into catalogue items
CatalogueItem? catalogueItemFromSearchJson(Map<String, dynamic> json) {
  final mediaType = json['media_type'] as String?;
  if (mediaType == 'movie') return Film.fromJson(json);
  if (mediaType == 'tv') return TvShow.fromJson(json);
  return null;
}
