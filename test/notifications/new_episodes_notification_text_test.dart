import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/new_episodes_notification_text.dart';
import 'package:iz_show_time_tracker/core/notifications/new_episodes_summary.dart';
import 'package:iz_show_time_tracker/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  String body(int episodeCount, List<String> showTitles) =>
      newEpisodesNotificationBody(
        l10n,
        NewEpisodesSummary(
          episodeCount: episodeCount,
          showTitles: showTitles,
        ),
      );

  test('uses the generic text without show titles', () {
    expect(body(1, []), l10n.notificationBodyOne);
    expect(body(3, []), l10n.notificationBodyOther(3));
  });

  test('names a single show', () {
    expect(body(1, ['A']), 'A new episode of A');
    expect(body(3, ['A']), '3 new episodes of A');
  });

  test('names two shows', () {
    expect(body(2, ['A', 'B']), '2 new episodes of A and B');
  });

  test('names two shows and counts the others', () {
    expect(body(4, ['A', 'B', 'C']), '4 new episodes of A, B and 1 more show');
    expect(
      body(5, ['A', 'B', 'C', 'D']),
      '5 new episodes of A, B and 2 more shows',
    );
  });
}
