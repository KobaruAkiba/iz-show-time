import '../../l10n/l10n.dart';
import 'episode_model.dart';

/// A newly detected episode for a catalogue TV show.
class NewEpisodeAlert {
  final int showId;
  final String showTitle;
  final String? showPosterPath;
  final int episodeId;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeName;
  final DateTime? airDate;
  /// Resolved catalogue runtime (episode or show-average fallback) at detection.
  final int? runtimeMinutes;
  final DateTime detectedAt;

  /// Episodes of the same season already aired after this one: with this
  /// episode, they are what the system notification counts.
  final List<LaterAiredEpisode> laterAiredEpisodes;

  const NewEpisodeAlert({
    required this.showId,
    required this.showTitle,
    this.showPosterPath,
    required this.episodeId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeName,
    this.airDate,
    this.runtimeMinutes,
    required this.detectedAt,
    this.laterAiredEpisodes = const [],
  });

  factory NewEpisodeAlert.fromJson(Map<String, dynamic> json) {
    return NewEpisodeAlert(
      showId: json['show_id'] as int,
      showTitle: json['show_title'] as String? ?? '',
      showPosterPath: json['show_poster_path'] as String?,
      episodeId: json['episode_id'] as int,
      seasonNumber: json['season_number'] as int? ?? 1,
      episodeNumber: json['episode_number'] as int? ?? 0,
      episodeName: json['episode_name'] as String? ?? '',
      airDate: EpisodeModel.parseAirDate(json['air_date'] as String?),
      runtimeMinutes: json['runtime_minutes'] as int?,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      laterAiredEpisodes: LaterAiredEpisode.listFromJson(json['later_aired']),
    );
  }

  Map<String, dynamic> toJson() => {
        'show_id': showId,
        'show_title': showTitle,
        'show_poster_path': showPosterPath,
        'episode_id': episodeId,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'episode_name': episodeName,
        'air_date': airDate?.toIso8601String(),
        'runtime_minutes': runtimeMinutes,
        'detected_at': detectedAt.toIso8601String(),
        if (laterAiredEpisodes.isNotEmpty)
          'later_aired': [
            for (final episode in laterAiredEpisodes) episode.toJson(),
          ],
      };

  String get episodeCode {
    final l10n = AppL10n.current;
    return '${l10n.seasonCode(seasonNumber)} ${l10n.episodeCode(episodeNumber)}';
  }

  String get displayTitle => episodeName.isNotEmpty
      ? episodeName
      : AppL10n.current.episodeFallbackTitle(episodeNumber);

  /// True when this alert's TMDB air date is today's local calendar day.
  bool get showsNewBadge => EpisodeModel.isAiredToday(airDate);

  /// Whether this alert is catalogue-addable (same bar as add-to-catalogue).
  bool get isCatalogueAddable => EpisodeModel.isCatalogueAddableFields(
        airDate: airDate,
        runtimeMinutes: runtimeMinutes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewEpisodeAlert && episodeId == other.episodeId;

  @override
  int get hashCode => episodeId.hashCode;
}

/// An aired episode after the one of a [NewEpisodeAlert], in the same season.
class LaterAiredEpisode {
  final int episodeId;
  final DateTime airDate;

  const LaterAiredEpisode({required this.episodeId, required this.airDate});

  Map<String, dynamic> toJson() => {
        'episode_id': episodeId,
        'air_date': airDate.toIso8601String(),
      };

  /// Skips malformed entries; alerts saved before this field read as empty.
  static List<LaterAiredEpisode> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map &&
            entry['episode_id'] is int &&
            EpisodeModel.parseAirDate(entry['air_date'] as String?) != null)
          LaterAiredEpisode(
            episodeId: entry['episode_id'] as int,
            airDate: EpisodeModel.parseAirDate(entry['air_date'] as String?)!,
          ),
    ];
  }
}
