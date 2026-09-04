import '../../core/constants/api_constants.dart';
import 'season_model.dart';

/// Lightweight cast entry parsed from TMDB credits / aggregate_credits.
class MediaCastMember {
  final String name;
  final String? character;
  final String? profilePath;

  const MediaCastMember({
    required this.name,
    this.character,
    this.profilePath,
  });
}

/// Compact related title from recommendations / similar.
class RelatedMediaPreview {
  final int id;
  final String title;
  final String? posterPath;
  final bool isFilm;

  const RelatedMediaPreview({
    required this.id,
    required this.title,
    this.posterPath,
    required this.isFilm,
  });
}

/// Alternate episode ordering group (TV).
class MediaEpisodeGroup {
  final String id;
  final String name;
  final int? type;

  const MediaEpisodeGroup({
    required this.id,
    required this.name,
    this.type,
  });
}

/// View model for TMDB detail responses (base + append_to_response).
class MediaDetails {
  final String title;
  final String? overview;
  final String? tagline;
  final String? status;
  final String? director;
  final int? runtimeMinutes;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final int? averageEpisodeRuntimeMinutes;
  final int? year;
  final String? posterPath;
  final String? backdropPath;
  final String? homepage;
  final String? originalLanguage;
  final double? voteAverage;
  final int? voteCount;
  final bool isFilm;
  final List<SeasonModel> seasons;
  final List<String> genres;
  final List<String> networkNames;
  final String? lastAirDate;
  final String? nextEpisodeAirDate;
  final List<MediaCastMember> cast;
  final String? certification;
  final List<String> keywordNames;
  final String? imdbId;
  final int? tvdbId;
  final List<String> watchProviderNames;
  final List<RelatedMediaPreview> related;
  final int? reviewCount;
  final List<String> alternativeTitles;
  final List<MediaEpisodeGroup> episodeGroups;

  const MediaDetails({
    required this.title,
    this.overview,
    this.tagline,
    this.status,
    this.director,
    this.runtimeMinutes,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.averageEpisodeRuntimeMinutes,
    this.year,
    this.posterPath,
    this.backdropPath,
    this.homepage,
    this.originalLanguage,
    this.voteAverage,
    this.voteCount,
    this.isFilm = true,
    this.seasons = const [],
    this.genres = const [],
    this.networkNames = const [],
    this.lastAirDate,
    this.nextEpisodeAirDate,
    this.cast = const [],
    this.certification,
    this.keywordNames = const [],
    this.imdbId,
    this.tvdbId,
    this.watchProviderNames = const [],
    this.related = const [],
    this.reviewCount,
    this.alternativeTitles = const [],
    this.episodeGroups = const [],
  });

  factory MediaDetails.fromTmdbJson(
    Map<String, dynamic> json, {
    required bool isFilm,
  }) {
    final title = isFilm
        ? json['title'] as String? ?? json['original_title'] as String? ?? ''
        : json['name'] as String? ?? json['original_name'] as String? ?? '';

    final dateStr = isFilm
        ? json['release_date'] as String?
        : json['first_air_date'] as String?;

    int? year;
    if (dateStr != null && dateStr.length >= 4) {
      year = int.tryParse(dateStr.substring(0, 4));
    }

    int? runtime;
    int? seasons;
    int? episodeCount;
    int? avgEpisodeRuntime;
    if (isFilm) {
      runtime = json['runtime'] as int?;
    } else {
      seasons = json['number_of_seasons'] as int?;
      episodeCount = json['number_of_episodes'] as int?;
      final runTimes = (json['episode_run_time'] as List<dynamic>?)
              ?.whereType<num>()
              .map((value) => value.toInt())
              .where((value) => value > 0)
              .toList() ??
          [];
      if (runTimes.isNotEmpty) {
        avgEpisodeRuntime =
            runTimes.reduce((a, b) => a + b) ~/ runTimes.length;
      }
    }

    return MediaDetails(
      title: title,
      overview: json['overview'] as String?,
      tagline: _nonEmptyString(json['tagline']),
      status: _nonEmptyString(json['status']),
      director: _parseDirector(json, isFilm: isFilm),
      runtimeMinutes: runtime,
      numberOfSeasons: seasons,
      numberOfEpisodes: episodeCount,
      averageEpisodeRuntimeMinutes: avgEpisodeRuntime,
      year: year,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      homepage: _nonEmptyString(json['homepage']),
      originalLanguage: _nonEmptyString(json['original_language']),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: (json['vote_count'] as num?)?.toInt(),
      isFilm: isFilm,
      genres: _parseNamedList(json['genres']),
      networkNames: isFilm ? const [] : _parseNamedList(json['networks']),
      lastAirDate: isFilm ? null : _nonEmptyString(json['last_air_date']),
      nextEpisodeAirDate: isFilm
          ? null
          : _nonEmptyString(
              (json['next_episode_to_air'] as Map<String, dynamic>?)
                  ?['air_date'],
            ),
      cast: _parseCast(json, isFilm: isFilm),
      certification: _parseCertification(json, isFilm: isFilm),
      keywordNames: _parseKeywords(json, isFilm: isFilm),
      imdbId: _parseImdbId(json, isFilm: isFilm),
      tvdbId: isFilm
          ? null
          : (json['external_ids'] as Map<String, dynamic>?)?['tvdb_id'] as int?,
      watchProviderNames: _parseWatchProviders(json),
      related: _parseRelated(json, isFilm: isFilm),
      reviewCount: _parseReviewCount(json),
      alternativeTitles: _parseAlternativeTitles(json, isFilm: isFilm),
      episodeGroups: isFilm ? const [] : _parseEpisodeGroups(json),
    );
  }

  String? get formattedRuntime {
    if (runtimeMinutes == null || runtimeMinutes! <= 0) return null;
    final hours = runtimeMinutes! ~/ 60;
    final minutes = runtimeMinutes! % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  String? get formattedSeasons {
    if (numberOfSeasons == null || numberOfSeasons! <= 0) return null;
    return numberOfSeasons == 1 ? '1 season' : '$numberOfSeasons seasons';
  }
}

String? _nonEmptyString(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _parseNamedList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map((item) => item['name'] as String?)
      .whereType<String>()
      .where((name) => name.trim().isNotEmpty)
      .toList();
}

String? _parseDirector(Map<String, dynamic> json, {required bool isFilm}) {
  if (isFilm) {
    final credits = json['credits'] as Map<String, dynamic>?;
    final crew = credits?['crew'] as List<dynamic>? ?? [];
    for (final member in crew) {
      if (member is Map<String, dynamic> && member['job'] == 'Director') {
        return member['name'] as String?;
      }
    }
    return null;
  }

  final creators = json['created_by'] as List<dynamic>? ?? [];
  final names = creators
      .whereType<Map<String, dynamic>>()
      .map((c) => c['name'] as String?)
      .whereType<String>()
      .toList();
  return names.isEmpty ? null : names.join(', ');
}

List<MediaCastMember> _parseCast(
  Map<String, dynamic> json, {
  required bool isFilm,
}) {
  final source = isFilm
      ? json['credits'] as Map<String, dynamic>?
      : (json['aggregate_credits'] as Map<String, dynamic>?) ??
          json['credits'] as Map<String, dynamic>?;
  final cast = source?['cast'] as List<dynamic>? ?? [];
  final parsed = <MediaCastMember>[];

  for (final entry in cast) {
    if (entry is! Map<String, dynamic>) continue;
    final name = entry['name'] as String?;
    if (name == null || name.trim().isEmpty) continue;

    String? character = entry['character'] as String?;
    if (!isFilm && (character == null || character.isEmpty)) {
      final roles = entry['roles'] as List<dynamic>? ?? [];
      final roleNames = roles
          .whereType<Map<String, dynamic>>()
          .map((role) => role['character'] as String?)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toList();
      if (roleNames.isNotEmpty) character = roleNames.join(' / ');
    }

    parsed.add(
      MediaCastMember(
        name: name,
        character: _nonEmptyString(character),
        profilePath: entry['profile_path'] as String?,
      ),
    );
    if (parsed.length >= 10) break;
  }

  return parsed;
}

String? _parseCertification(
  Map<String, dynamic> json, {
  required bool isFilm,
}) {
  final preferred = ApiConstants.watchProviderRegion;

  if (isFilm) {
    final releaseDates = json['release_dates'] as Map<String, dynamic>?;
    final results = releaseDates?['results'] as List<dynamic>? ?? [];
    Map<String, dynamic>? preferredCountry;
    Map<String, dynamic>? fallbackCountry;

    for (final entry in results) {
      if (entry is! Map<String, dynamic>) continue;
      fallbackCountry ??= entry;
      if (entry['iso_3166_1'] == preferred) {
        preferredCountry = entry;
        break;
      }
    }

    final country = preferredCountry ?? fallbackCountry;
    final dates = country?['release_dates'] as List<dynamic>? ?? [];
    for (final date in dates) {
      if (date is! Map<String, dynamic>) continue;
      final cert = _nonEmptyString(date['certification']);
      if (cert != null) return cert;
    }
    return null;
  }

  final contentRatings = json['content_ratings'] as Map<String, dynamic>?;
  final results = contentRatings?['results'] as List<dynamic>? ?? [];
  String? fallback;
  for (final entry in results) {
    if (entry is! Map<String, dynamic>) continue;
    final rating = _nonEmptyString(entry['rating']);
    if (rating == null) continue;
    if (entry['iso_3166_1'] == preferred) return rating;
    fallback ??= rating;
  }
  return fallback;
}

List<String> _parseKeywords(
  Map<String, dynamic> json, {
  required bool isFilm,
}) {
  final keywords = json['keywords'] as Map<String, dynamic>?;
  if (keywords == null) return const [];
  final raw = isFilm ? keywords['keywords'] : keywords['results'];
  return _parseNamedList(raw);
}

String? _parseImdbId(Map<String, dynamic> json, {required bool isFilm}) {
  if (isFilm) {
    final direct = _nonEmptyString(json['imdb_id']);
    if (direct != null) return direct;
  }
  final external = json['external_ids'] as Map<String, dynamic>?;
  return _nonEmptyString(external?['imdb_id']);
}

List<String> _parseWatchProviders(Map<String, dynamic> json) {
  final providers = json['watch/providers'] as Map<String, dynamic>?;
  final results = providers?['results'] as Map<String, dynamic>?;
  if (results == null || results.isEmpty) return const [];

  final region = results[ApiConstants.watchProviderRegion] as Map<String, dynamic>? ??
      results.values.whereType<Map<String, dynamic>>().firstOrNull;
  if (region == null) return const [];

  final names = <String>{};
  for (final key in ['flatrate', 'rent', 'buy', 'ads', 'free']) {
    final list = region[key] as List<dynamic>? ?? [];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final name = _nonEmptyString(entry['provider_name']);
      if (name != null) names.add(name);
    }
  }
  return names.toList();
}

List<RelatedMediaPreview> _parseRelated(
  Map<String, dynamic> json, {
  required bool isFilm,
}) {
  final previews = <RelatedMediaPreview>[];
  final seenIds = <int>{};

  void collect(dynamic block) {
    if (block is! Map<String, dynamic>) return;
    final results = block['results'] as List<dynamic>? ?? [];
    for (final entry in results) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id'] as int?;
      if (id == null || seenIds.contains(id)) continue;
      final title = isFilm
          ? entry['title'] as String? ?? entry['original_title'] as String?
          : entry['name'] as String? ?? entry['original_name'] as String?;
      if (title == null || title.trim().isEmpty) continue;
      seenIds.add(id);
      previews.add(
        RelatedMediaPreview(
          id: id,
          title: title,
          posterPath: entry['poster_path'] as String?,
          isFilm: isFilm,
        ),
      );
      if (previews.length >= 10) return;
    }
  }

  collect(json['recommendations']);
  if (previews.length < 10) collect(json['similar']);
  return previews;
}

int? _parseReviewCount(Map<String, dynamic> json) {
  final reviews = json['reviews'] as Map<String, dynamic>?;
  if (reviews == null) return null;
  final total = (reviews['total_results'] as num?)?.toInt();
  if (total != null) return total;
  final results = reviews['results'] as List<dynamic>?;
  return results?.length;
}

List<String> _parseAlternativeTitles(
  Map<String, dynamic> json, {
  required bool isFilm,
}) {
  final block = json['alternative_titles'] as Map<String, dynamic>?;
  if (block == null) return const [];
  final raw = isFilm ? block['titles'] : block['results'];
  if (raw is! List) return const [];

  final titles = <String>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) continue;
    final title = _nonEmptyString(entry['title']) ??
        _nonEmptyString(entry['name']);
    if (title != null) titles.add(title);
  }
  return titles;
}

List<MediaEpisodeGroup> _parseEpisodeGroups(Map<String, dynamic> json) {
  final block = json['episode_groups'] as Map<String, dynamic>?;
  final results = block?['results'] as List<dynamic>? ?? [];
  final groups = <MediaEpisodeGroup>[];

  for (final entry in results) {
    if (entry is! Map<String, dynamic>) continue;
    final id = entry['id']?.toString();
    final name = _nonEmptyString(entry['name']);
    if (id == null || name == null) continue;
    groups.add(
      MediaEpisodeGroup(
        id: id,
        name: name,
        type: (entry['type'] as num?)?.toInt(),
      ),
    );
  }
  return groups;
}
