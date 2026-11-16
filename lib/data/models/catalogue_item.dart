import '../../core/constants/api_constants.dart';

/// Reserved catalogue tag for user favorites.
const String kFavoriteTag = 'favorite';

/// Reserved catalogue tag for followed TV shows (new-episode alerts).
const String kFollowedTag = 'followed';

/// Composite key for a film or TV show.
///
/// TMDB numbers `movie/` and `tv/` independently, so the bare id is not unique.
String mediaKeyOf({required bool isFilm, required int id}) =>
    '${isFilm ? 'm' : 't'}_$id';

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

  bool get isFollowed => containsTag(kFollowedTag);

  CatalogueItem withFollowed(bool followed) {
    if (followed == isFollowed) return this;
    if (followed) return copyWithTags([...tags, kFollowedTag]);
    return copyWithTags(withoutTag(kFollowedTag));
  }

  bool get isFilm => this is Film;
  bool get isTvShow => this is TvShow;

  /// Identity of this item across catalogue, storage and UI lists.
  String get mediaKey => mediaKeyOf(isFilm: isFilm, id: id);
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

  /// TMDB series lifecycle status (e.g. Returning Series, Ended).
  final String? status;

  /// ISO date of TMDB `next_episode_to_air`, when known.
  final String? nextEpisodeAirDate;

  /// Season number of TMDB `last_episode_to_air`, when known.
  final int? lastAiredSeasonNumber;

  /// Episode number of TMDB `last_episode_to_air`, when known.
  final int? lastAiredEpisodeNumber;

  const TvShow({
    required super.id,
    required super.title,
    this.overview,
    this.posterPath,
    this.voteAverage = 0.0,
    this.status,
    this.nextEpisodeAirDate,
    this.lastAiredSeasonNumber,
    this.lastAiredEpisodeNumber,
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
      status: _nonEmptyString(json['status']),
      nextEpisodeAirDate: _nonEmptyString(json['next_episode_air_date']),
      lastAiredSeasonNumber: (json['last_aired_season'] as num?)?.toInt(),
      lastAiredEpisodeNumber: (json['last_aired_episode'] as num?)?.toInt(),
      tags: _parseTags(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': title,
        'overview': overview,
        'poster_path': posterPath,
        'vote_average': voteAverage,
        if (status != null) 'status': status,
        if (nextEpisodeAirDate != null)
          'next_episode_air_date': nextEpisodeAirDate,
        if (lastAiredSeasonNumber != null)
          'last_aired_season': lastAiredSeasonNumber,
        if (lastAiredEpisodeNumber != null)
          'last_aired_episode': lastAiredEpisodeNumber,
        'tags': tags,
      };

  TvShow copyWith({
    String? overview,
    String? posterPath,
    double? voteAverage,
    String? status,
    String? nextEpisodeAirDate,
    int? lastAiredSeasonNumber,
    int? lastAiredEpisodeNumber,
    List<String>? tags,
    bool clearStatus = false,
    bool clearNextEpisodeAirDate = false,
    bool clearLastAiredEpisode = false,
  }) =>
      TvShow(
        id: id,
        title: title,
        overview: overview ?? this.overview,
        posterPath: posterPath ?? this.posterPath,
        voteAverage: voteAverage ?? this.voteAverage,
        status: clearStatus ? null : (status ?? this.status),
        nextEpisodeAirDate: clearNextEpisodeAirDate
            ? null
            : (nextEpisodeAirDate ?? this.nextEpisodeAirDate),
        lastAiredSeasonNumber: clearLastAiredEpisode
            ? null
            : (lastAiredSeasonNumber ?? this.lastAiredSeasonNumber),
        lastAiredEpisodeNumber: clearLastAiredEpisode
            ? null
            : (lastAiredEpisodeNumber ?? this.lastAiredEpisodeNumber),
        tags: tags ?? this.tags,
      );

  @override
  TvShow copyWithTags(List<String> newTags) => copyWith(tags: newTags);

  @override
  String toString() => 'TvShow(id: $id, name: $title)';
}

List<String> _parseTags(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((entry) => entry.toString()).toList(growable: false);
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Drops bulky fields (overview) kept only for API/search display.
/// Use before persisting or holding items long-term in the local catalogue.
CatalogueItem catalogueItemForLocalStore(CatalogueItem item) {
  return switch (item) {
    Film film => Film(
        id: film.id,
        title: film.title,
        posterPath: film.posterPath,
        voteAverage: film.voteAverage,
        tags: film.tags,
      ),
    TvShow show => TvShow(
        id: show.id,
        title: show.title,
        posterPath: show.posterPath,
        voteAverage: show.voteAverage,
        status: show.status,
        nextEpisodeAirDate: show.nextEpisodeAirDate,
        lastAiredSeasonNumber: show.lastAiredSeasonNumber,
        lastAiredEpisodeNumber: show.lastAiredEpisodeNumber,
        tags: show.tags,
      ),
    _ => throw ArgumentError(
        'Unsupported catalogue item type: ${item.runtimeType}'),
  };
}

/// Serializes a catalogue item for local storage with a type discriminator.
/// Omits overview to keep on-device catalogue payloads small.
Map<String, dynamic> catalogueItemToStorageJson(CatalogueItem item) {
  final trimmed = catalogueItemForLocalStore(item);
  final payload = switch (trimmed) {
    Film film => {
        'id': film.id,
        'title': film.title,
        'poster_path': film.posterPath,
        'vote_average': film.voteAverage,
        'tags': film.tags,
      },
    TvShow show => {
        'id': show.id,
        'name': show.title,
        'poster_path': show.posterPath,
        'vote_average': show.voteAverage,
        if (show.status != null) 'status': show.status,
        if (show.nextEpisodeAirDate != null)
          'next_episode_air_date': show.nextEpisodeAirDate,
        if (show.lastAiredSeasonNumber != null)
          'last_aired_season': show.lastAiredSeasonNumber,
        if (show.lastAiredEpisodeNumber != null)
          'last_aired_episode': show.lastAiredEpisodeNumber,
        'tags': show.tags,
      },
    _ => throw ArgumentError(
        'Unsupported catalogue item type: ${trimmed.runtimeType}'),
  };
  return {
    'type': trimmed is Film ? 'film' : 'tv',
    ...payload,
  };
}

/// Restores a catalogue item from local storage JSON.
/// Legacy `overview` blobs are ignored so old installs shrink on rewrite.
CatalogueItem? catalogueItemFromStorageJson(Map<String, dynamic> json) {
  final cleaned = Map<String, dynamic>.from(json)..remove('overview');
  switch (cleaned['type']) {
    case 'film':
      return Film.fromJson(cleaned);
    case 'tv':
      return TvShow.fromJson(cleaned);
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
