import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/widgets/catalogue_stats_row.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_filters.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

CatalogueStatsRow _row({required bool hideWatchTime, int totalCount = 3}) =>
    CatalogueStatsRow(
      tvShowCount: 2,
      filmCount: 1,
      totalCount: totalCount,
      watchTimeMinutes: 90,
      hideWatchTime: hideWatchTime,
      expanded: false,
      onToggleExpanded: () {},
      selectedFilter: MediaFilter.all,
      onFilterSelected: (_) {},
    );

void main() {
  testWidgets('shows total watch time by default', (tester) async {
    await tester.pumpWidget(_wrap(_row(hideWatchTime: false)));

    expect(find.text('Total Watch Time'), findsOneWidget);
    expect(find.text('Your Catalogue'), findsNothing);
  });

  testWidgets('shows catalogue summary when watch time is hidden',
      (tester) async {
    await tester.pumpWidget(_wrap(_row(hideWatchTime: true)));

    expect(find.text('Your Catalogue'), findsOneWidget);
    expect(find.text('3 titles'), findsOneWidget);
    expect(find.text('Total Watch Time'), findsNothing);
  });

  testWidgets('catalogue summary handles singular and empty catalogue',
      (tester) async {
    await tester.pumpWidget(_wrap(_row(hideWatchTime: true, totalCount: 1)));
    expect(find.text('1 title'), findsOneWidget);

    await tester.pumpWidget(_wrap(_row(hideWatchTime: true, totalCount: 0)));
    expect(find.text('No titles yet'), findsOneWidget);
  });
}
