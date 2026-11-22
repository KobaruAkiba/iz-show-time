import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/new_episodes_summary.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';

NewEpisodeAlert _alert({
  required int showId,
  required String showTitle,
  required int episodeId,
  List<int> laterEpisodeIds = const [],
}) {
  return NewEpisodeAlert(
    showId: showId,
    showTitle: showTitle,
    episodeId: episodeId,
    seasonNumber: 1,
    episodeNumber: 2,
    episodeName: 'E2',
    detectedAt: DateTime(2026, 11, 20),
    laterAiredEpisodes: [
      for (final id in laterEpisodeIds)
        LaterAiredEpisode(episodeId: id, airDate: DateTime(2026, 11, 19)),
    ],
  );
}

void main() {
  final alerts = [
    _alert(showId: 1, showTitle: 'A', episodeId: 12, laterEpisodeIds: [13]),
    _alert(showId: 2, showTitle: 'B', episodeId: 22),
    _alert(showId: 3, showTitle: 'C', episodeId: 32),
  ];

  test('counts ids and lists each show once', () {
    final summary = summarizeNotifiedEpisodes(
      episodeIds: {12, 13, 22},
      alerts: alerts,
    );

    expect(summary.episodeCount, 3);
    expect(summary.showTitles, ['A', 'B']);
  });

  test('keeps the count for ids without an alert', () {
    final summary = summarizeNotifiedEpisodes(
      episodeIds: {12, 99},
      alerts: alerts,
    );

    expect(summary.episodeCount, 2);
    expect(summary.showTitles, ['A']);
  });

  test('skips empty show titles', () {
    final summary = summarizeNotifiedEpisodes(
      episodeIds: {12, 42},
      alerts: [
        ...alerts,
        _alert(showId: 4, showTitle: '', episodeId: 42),
      ],
    );

    expect(summary.episodeCount, 2);
    expect(summary.showTitles, ['A']);
  });
}
