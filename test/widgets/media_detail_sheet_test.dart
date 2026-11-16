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
}
