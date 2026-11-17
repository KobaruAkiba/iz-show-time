import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/widgets/catalogue_stats_row.dart';

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

CatalogueStatsRow _row({
  required bool hideWatchTime,
  int totalCount = 3,
  int watchTimeMinutes = 90,
}) =>
    CatalogueStatsRow(
      totalCount: totalCount,
      watchTimeMinutes: watchTimeMinutes,
      hideWatchTime: hideWatchTime,
    );

void main() {
  testWidgets('shows total watch time and title count on one line',
      (tester) async {
    await tester.pumpWidget(_wrap(_row(hideWatchTime: false)));

    expect(find.text('1h 30m · 3 titles'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('shows only the title count when watch time is hidden',
      (tester) async {
    await tester.pumpWidget(_wrap(_row(hideWatchTime: true)));

    expect(find.text('3 titles'), findsOneWidget);
    expect(find.textContaining('1h 30m'), findsNothing);
    expect(find.byIcon(Icons.collections_bookmark_outlined), findsOneWidget);
  });

  testWidgets('title count handles singular and empty catalogue',
      (tester) async {
    await tester.pumpWidget(_wrap(_row(hideWatchTime: true, totalCount: 1)));
    expect(find.text('1 title'), findsOneWidget);

    await tester.pumpWidget(_wrap(_row(hideWatchTime: true, totalCount: 0)));
    expect(find.text('No titles yet'), findsOneWidget);
  });

  testWidgets('is a thin row, not a card', (tester) async {
    await tester.pumpWidget(_wrap(_row(hideWatchTime: false)));

    expect(tester.getSize(find.byType(CatalogueStatsRow)).height, 40);
  });

  testWidgets('announces one merged label with the metric name',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(_row(hideWatchTime: false)));
    expect(
      find.bySemanticsLabel('Total Watch Time, 1h 30m, 3 titles'),
      findsOneWidget,
    );

    await tester.pumpWidget(_wrap(_row(hideWatchTime: true)));
    expect(find.bySemanticsLabel('Your Catalogue, 3 titles'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('wraps instead of truncating at 200% text size', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(
      _row(hideWatchTime: false, watchTimeMinutes: 100000),
      textScale: 2,
    ));

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(
      tester.getSize(find.byType(CatalogueStatsRow)).height,
      greaterThan(40),
    );
  });
}
