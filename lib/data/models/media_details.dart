import 'season_model.dart';

/// Lightweight view model for TMDB detail responses shown on Home tap.
class MediaDetails {
  final String title;
  final String? overview;
  final String? director;
  final int? runtimeMinutes;
  final int? numberOfSeasons;
  final int? averageEpisodeRuntimeMinutes;
  final int? year;
  final String? posterPath;
  final bool isFilm;
  final List<SeasonModel> seasons;

  const MediaDetails({
    required this.title,
    this.overview,
    this.director,
    this.runtimeMinutes,
    this.numberOfSeasons,
    this.averageEpisodeRuntimeMinutes,
    this.year,
    this.posterPath,
    this.isFilm = true,
    this.seasons = const [],
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
    int? avgEpisodeRuntime;
    if (isFilm) {
      runtime = json['runtime'] as int?;
    } else {
      seasons = json['number_of_seasons'] as int?;
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

    String? director;
    if (isFilm) {
      final credits = json['credits'] as Map<String, dynamic>?;
      final crew = credits?['crew'] as List<dynamic>? ?? [];
      for (final member in crew) {
        if (member is Map<String, dynamic> && member['job'] == 'Director') {
          director = member['name'] as String?;
          break;
        }
      }
    } else {
      final creators = json['created_by'] as List<dynamic>? ?? [];
      final names = creators
          .whereType<Map<String, dynamic>>()
          .map((c) => c['name'] as String?)
          .whereType<String>()
          .toList();
      if (names.isNotEmpty) director = names.join(', ');
    }

    return MediaDetails(
      title: title,
      overview: json['overview'] as String?,
      director: director,
      runtimeMinutes: runtime,
      numberOfSeasons: seasons,
      averageEpisodeRuntimeMinutes: avgEpisodeRuntime,
      year: year,
      posterPath: json['poster_path'] as String?,
      isFilm: isFilm,
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
