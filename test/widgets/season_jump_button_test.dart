import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/presentation/widgets/season_jump_button.dart';

EpisodeModel _episode(int number, {String? airDate}) => EpisodeModel.fromJson({
      'id': number,
      'season_number': 1,
      'episode_number': number,
      'name': 'Episode $number',
      'air_date': airDate,
    });

void main() {
  group('latestAiredEpisodeIndex', () {
    test('skips upcoming episodes at the end of the season', () {
      final episodes = [
        _episode(1, airDate: '2020-01-01'),
        _episode(2, airDate: '2020-01-08'),
        _episode(3, airDate: '2099-01-01'),
      ];
      expect(latestAiredEpisodeIndex(episodes), 1);
    });

    test('prefers a dated episode over trailing undated placeholders', () {
      final episodes = [
        _episode(1, airDate: '2020-01-01'),
        _episode(2),
      ];
      expect(latestAiredEpisodeIndex(episodes), 0);
    });

    test('falls back to the last undated episode when none is dated', () {
      expect(latestAiredEpisodeIndex([_episode(1), _episode(2)]), 1);
    });

    test('is null when every episode is upcoming', () {
      expect(
        latestAiredEpisodeIndex([_episode(1, airDate: '2099-01-01')]),
        isNull,
      );
    });
  });

  group('resolveSeasonJumpTarget', () {
    const viewport = 500.0;
    const inset = 80.0;

    SeasonJumpTarget? resolve(
      List<SeasonJumpSpan> spans, {
      bool scrolledToEnd = false,
    }) =>
        resolveSeasonJumpTarget(
          spans,
          viewportHeight: viewport,
          bottomInset: inset,
          scrolledToEnd: scrolledToEnd,
        );

    test('hidden when the season fits above the button', () {
      expect(
        resolve(const [
          SeasonJumpSpan(seasonNumber: 1, firstTop: 100, latestBottom: 400),
        ]),
        isNull,
      );
    });

    test('offers the latest episode while it is below the button', () {
      expect(
        resolve(const [
          SeasonJumpSpan(seasonNumber: 1, firstTop: 200, latestBottom: 1500),
        ]),
        const SeasonJumpTarget(
          seasonNumber: 1,
          direction: SeasonJumpDirection.toLatest,
        ),
      );
    });

    test('mid-season still offers the latest episode', () {
      expect(
        resolve(const [
          SeasonJumpSpan(seasonNumber: 1, firstTop: -600, latestBottom: 900),
        ])?.direction,
        SeasonJumpDirection.toLatest,
      );
    });

    test('offers the first episode once the latest is in view', () {
      expect(
        resolve(const [
          SeasonJumpSpan(seasonNumber: 1, firstTop: -1000, latestBottom: 410),
        ]),
        const SeasonJumpTarget(
          seasonNumber: 1,
          direction: SeasonJumpDirection.toFirst,
        ),
      );
    });

    test('at the end of the list it stops offering the latest episode', () {
      expect(
        resolve(
          const [
            SeasonJumpSpan(seasonNumber: 1, firstTop: -1000, latestBottom: 460),
          ],
          scrolledToEnd: true,
        )?.direction,
        SeasonJumpDirection.toFirst,
      );
    });

    test('hidden when the season is off screen', () {
      expect(
        resolve(const [
          SeasonJumpSpan(seasonNumber: 1, firstTop: 600, latestBottom: 2000),
        ]),
        isNull,
      );
    });

    test('picks the season with the largest visible part', () {
      expect(
        resolve(const [
          SeasonJumpSpan(seasonNumber: 1, firstTop: -1500, latestBottom: 100),
          SeasonJumpSpan(seasonNumber: 2, firstTop: 150, latestBottom: 1800),
        ])?.seasonNumber,
        2,
      );
    });

    group('switching between two expanded seasons', () {
      // Season 1 shows 200px, season 2 shows 230px: 30px more.
      const spans = [
        SeasonJumpSpan(seasonNumber: 1, firstTop: -1500, latestBottom: 200),
        SeasonJumpSpan(seasonNumber: 2, firstTop: 270, latestBottom: 1800),
      ];

      test('keeps the current season while the other leads by little', () {
        expect(
          resolveSeasonJumpTarget(
            spans,
            viewportHeight: viewport,
            bottomInset: inset,
            currentSeason: 1,
          )?.seasonNumber,
          1,
        );
      });

      test('switches once the other season leads by the margin', () {
        const further = [
          SeasonJumpSpan(seasonNumber: 1, firstTop: -1500, latestBottom: 150),
          SeasonJumpSpan(seasonNumber: 2, firstTop: 220, latestBottom: 1800),
        ];
        expect(
          resolveSeasonJumpTarget(
            further,
            viewportHeight: viewport,
            bottomInset: inset,
            currentSeason: 1,
          )?.seasonNumber,
          2,
        );
      });

      test('without a current season the largest visible part wins', () {
        expect(resolve(spans)?.seasonNumber, 2);
      });
    });
  });
}
