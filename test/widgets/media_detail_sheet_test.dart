import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/network/api_error.dart';
import 'package:iz_show_time_tracker/core/services/app_services.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/episode_model.dart';
import 'package:iz_show_time_tracker/data/models/media_details.dart';
import 'package:iz_show_time_tracker/data/models/season_model.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_detail_sheet.dart';

/// Two seasons listed by the show payload; records which ones are fetched.
class _SheetStubTmdbService extends TmdbService {
  _SheetStubTmdbService({this.failingSeasons = const {}})
      : super(cacheManager: null);

  final Set<int> failingSeasons;
  final List<int> fetchedSeasons = [];

  @override
  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    return MediaDetails(
      title: item.title,
      isFilm: false,
      numberOfSeasons: 2,
      seasonSummaries: [
        SeasonSummary(
          seasonNumber: 1,
          episodeCount: 2,
          airDate: DateTime(2020),
        ),
        SeasonSummary(
          seasonNumber: 2,
          episodeCount: 1,
          airDate: DateTime(2021),
        ),
      ],
    );
  }

  @override
  Future<SeasonModel?> getSeason({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    fetchedSeasons.add(seasonNumber);
    if (failingSeasons.contains(seasonNumber)) {
      throw const ApiException(ApiErrorType.notFound, 'missing season');
    }
    return SeasonModel(
      seasonNumber: seasonNumber,
      airDate: DateTime(2020),
      episodes: [
        EpisodeModel.fromJson({
          'id': seasonNumber * 100 + 1,
          'season_number': seasonNumber,
          'episode_number': 1,
          'name': 'Episode of season $seasonNumber',
          'air_date': '2020-01-01',
          'runtime': 40,
        }),
      ],
    );
  }
}

/// One long season: [airedCount] aired episodes, then [upcomingCount] future.
class _LongSeasonTmdbService extends TmdbService {
  _LongSeasonTmdbService({
    this.airedCount = 30,
    this.upcomingCount = 0,
    this.seasonCount = 1,
  }) : super(cacheManager: null);

  final int airedCount;
  final int upcomingCount;

  /// Identical seasons listed by the show, so the sheet can scroll.
  final int seasonCount;

  @override
  Future<MediaDetails?> getMediaDetails(CatalogueItem item) async {
    return MediaDetails(
      title: item.title,
      isFilm: false,
      numberOfSeasons: seasonCount,
      seasonSummaries: [
        for (var number = 1; number <= seasonCount; number++)
          SeasonSummary(
            seasonNumber: number,
            episodeCount: airedCount + upcomingCount,
            airDate: DateTime(2020),
          ),
      ],
    );
  }

  @override
  Future<SeasonModel?> getSeason({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async {
    return SeasonModel(
      seasonNumber: seasonNumber,
      airDate: DateTime(2020),
      episodes: [
        for (var number = 1; number <= airedCount + upcomingCount; number++)
          EpisodeModel.fromJson({
            'id': seasonNumber * 1000 + number,
            'season_number': seasonNumber,
            'episode_number': number,
            'name': 'Episode $number',
            'air_date': number <= airedCount ? '2020-01-01' : '2099-01-01',
            'runtime': 40,
          }),
      ],
    );
  }
}

void main() {
  const show = TvShow(id: 4242, title: 'Sheet Show');
  final appServices = AppServices();
  late TmdbService previousTmdb;

  setUp(() => previousTmdb = appServices.tmdbService);
  tearDown(() => appServices.tmdbService = previousTmdb);

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MediaDetailSheet(item: show)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists seasons from the show payload without fetching them',
      (tester) async {
    final tmdb = _SheetStubTmdbService();
    appServices.tmdbService = tmdb;

    await pumpSheet(tester);

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
    expect(find.text('2 episodes'), findsOneWidget);
    expect(tmdb.fetchedSeasons, isEmpty);
  });

  testWidgets('loads only the expanded season', (tester) async {
    final tmdb = _SheetStubTmdbService();
    appServices.tmdbService = tmdb;
    await pumpSheet(tester);

    await tester.tap(find.text('Season 1'));
    await tester.pumpAndSettle();

    expect(tmdb.fetchedSeasons, [1]);
    expect(find.text('Episode of season 1'), findsOneWidget);
  });

  testWidgets('a failed season shows a retry hint and reloads on tap',
      (tester) async {
    final tmdb = _SheetStubTmdbService(failingSeasons: {2});
    appServices.tmdbService = tmdb;
    await pumpSheet(tester);

    await tester.tap(find.text('Season 2'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load episodes. Tap to retry.'), findsOneWidget);
    expect(find.text('Season 1'), findsOneWidget);

    tmdb.failingSeasons.clear();
    await tester.tap(find.text('Season 2'));
    await tester.pumpAndSettle();

    expect(tmdb.fetchedSeasons, [2, 2]);
    expect(find.text('Episode of season 2'), findsOneWidget);
  });

  group('season jump button', () {
    Rect sheetRect(WidgetTester tester) =>
        tester.getRect(find.byType(CustomScrollView));

    /// The season header: the Material closest to its title.
    Rect headerRect(WidgetTester tester) => tester.getRect(
          find
              .ancestor(of: find.text('Season 1'), matching: find.byType(Material))
              .first,
        );

    Rect buttonRect(WidgetTester tester) =>
        tester.getRect(find.byType(FloatingActionButton));

    testWidgets('hidden for a season that fits on screen', (tester) async {
      appServices.tmdbService = _SheetStubTmdbService();
      await pumpSheet(tester);

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('jumps to the latest episode and back to the first',
        (tester) async {
      appServices.tmdbService = _LongSeasonTmdbService();
      await pumpSheet(tester);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();
      expect(find.text('S1 · Jump to latest'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Season 1, jump to latest episode'),
        findsOneWidget,
      );

      await tester.tap(find.text('S1 · Jump to latest'));
      await tester.pumpAndSettle();
      expect(find.text('S1 · Back to first'), findsOneWidget);
      // The latest episode sits above the button, not behind it.
      final latest = tester.getRect(find.text('Episode 30'));
      expect(latest.top, greaterThanOrEqualTo(sheetRect(tester).top));
      expect(latest.bottom, lessThanOrEqualTo(buttonRect(tester).top));

      await tester.tap(find.text('S1 · Back to first'));
      await tester.pumpAndSettle();
      expect(find.text('S1 · Jump to latest'), findsOneWidget);
      final header = headerRect(tester);
      final first = tester.getRect(find.text('Episode 1'));
      expect(header.top, greaterThanOrEqualTo(sheetRect(tester).top - 0.5));
      // The first episode shows right below the header, not under it.
      expect(first.top, greaterThanOrEqualTo(header.bottom));
      expect(first.bottom, lessThanOrEqualTo(sheetRect(tester).bottom));
    });

    testWidgets('stops at the latest aired episode, not upcoming ones',
        (tester) async {
      appServices.tmdbService =
          _LongSeasonTmdbService(airedCount: 25, upcomingCount: 5);
      await pumpSheet(tester);

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('S1 · Jump to latest'));
      await tester.pumpAndSettle();

      expect(find.text('S1 · Back to first'), findsOneWidget);
      final latestAired = tester.getRect(find.text('Episode 25'));
      expect(latestAired.bottom, lessThanOrEqualTo(buttonRect(tester).top));
      expect(latestAired.top, greaterThanOrEqualTo(sheetRect(tester).top));
    });

    testWidgets('jumps instantly with reduced motion', (tester) async {
      appServices.tmdbService = _LongSeasonTmdbService();
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(800, 600), disableAnimations: true),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: MediaDetailSheet(item: show)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('S1 · Jump to latest'));
      // One frame to scroll and re-measure, one to show the new label.
      await tester.pump();
      await tester.pump();

      expect(find.text('S1 · Back to first'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('outlines the targeted season only while the button shows',
        (tester) async {
      appServices.tmdbService = _LongSeasonTmdbService();
      await pumpSheet(tester);

      Color outlineColor() {
        final outline = tester.widget<DecoratedSliver>(
          find.ancestor(
            of: find.text('Season 1'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is DecoratedSliver &&
                  widget.position == DecorationPosition.foreground,
            ),
          ),
        );
        final decoration = outline.decoration as BoxDecoration;
        return (decoration.border! as Border).top.color;
      }

      final primary = Theme.of(tester.element(find.text('Season 1')))
          .colorScheme
          .primary;
      expect(outlineColor().a, 0);

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();
      expect(find.text('S1 · Jump to latest'), findsOneWidget);
      expect(outlineColor(), primary);

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(outlineColor().a, 0);
    });
  });

  testWidgets('expanding a season after scrolling keeps its header in place',
      (tester) async {
    appServices.tmdbService = _LongSeasonTmdbService(seasonCount: 8);
    await pumpSheet(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
    await tester.pumpAndSettle();

    Rect header() => tester.getRect(
          find
              .ancestor(
                of: find.text('Season 1'),
                matching: find.byType(Material),
              )
              .first,
        );
    final before = header();
    await tester.tap(find.text('Season 1'));
    await tester.pumpAndSettle();

    expect(header().top, closeTo(before.top, 0.5));
    expect(find.text('Episode 1'), findsOneWidget);
    expect(find.text('S1 · Jump to latest'), findsOneWidget);
  });

  testWidgets('the expanded season header stays pinned while scrolling',
      (tester) async {
    appServices.tmdbService = _LongSeasonTmdbService();
    await pumpSheet(tester);
    await tester.tap(find.text('Season 1'));
    await tester.pumpAndSettle();

    // First drag grows the sheet to full height, the second scrolls it.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.byType(CustomScrollView));
    final header = tester.getRect(
      find
          .ancestor(of: find.text('Season 1'), matching: find.byType(Material))
          .first,
    );
    expect(header.top, closeTo(sheet.top, 0.5));
    // Episodes scroll under the header.
    expect(tester.getRect(find.text('Episode 1')).top, lessThan(header.top));

    // Still tappable while pinned: collapsing the season.
    await tester.tap(find.text('Season 1'));
    await tester.pumpAndSettle();
    expect(find.text('Episode 1'), findsNothing);
  });
}
