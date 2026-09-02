import 'episode_model.dart';

/// A TV season with its episodes, used in detail views.
class SeasonModel {
  final int seasonNumber;
  final List<EpisodeModel> episodes;

  const SeasonModel({
    required this.seasonNumber,
    required this.episodes,
  });

  String get label =>
      seasonNumber == 1 ? 'Season 1' : 'Season $seasonNumber';
}
