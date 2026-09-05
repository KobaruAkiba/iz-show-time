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
  final DateTime detectedAt;

  const NewEpisodeAlert({
    required this.showId,
    required this.showTitle,
    this.showPosterPath,
    required this.episodeId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeName,
    this.airDate,
    required this.detectedAt,
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
      detectedAt: DateTime.parse(json['detected_at'] as String),
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
        'detected_at': detectedAt.toIso8601String(),
      };

  String get episodeCode {
    final l10n = AppL10n.current;
    return '${l10n.seasonCode(seasonNumber)} ${l10n.episodeCode(episodeNumber)}';
  }

  String get displayTitle => episodeName.isNotEmpty
      ? episodeName
      : AppL10n.current.episodeFallbackTitle(episodeNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewEpisodeAlert && episodeId == other.episodeId;

  @override
  int get hashCode => episodeId.hashCode;
}
