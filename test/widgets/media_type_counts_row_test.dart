import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_filters.dart';
import 'package:iz_show_time_tracker/presentation/widgets/media_type_counts_row.dart';

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

MediaTypeCountsRow _row({
  MediaFilter selected = MediaFilter.all,
  ValueChanged<MediaFilter>? onSelected,
}) =>
    MediaTypeCountsRow(
      tvShowCount: 2,
      filmCount: 1,
      selectedFilter: selected,
      onFilterSelected: onSelected ?? (_) {},
    );

void main() {
  testWidgets('shows the total and one count per media type', (tester) async {
    await tester.pumpWidget(_wrap(_row()));

    expect(find.text('All 3'), findsOneWidget);
    expect(find.text('Shows 2'), findsOneWidget);
    expect(find.text('Films 1'), findsOneWidget);
  });

  testWidgets('tapping a chip reports the matching filter', (tester) async {
    final selected = <MediaFilter>[];
    await tester.pumpWidget(_wrap(_row(onSelected: selected.add)));

    await tester.tap(find.text('Films 1'));
    await tester.tap(find.text('Shows 2'));
    await tester.tap(find.text('All 3'));

    expect(selected, [MediaFilter.filmsOnly, MediaFilter.tvOnly, MediaFilter.all]);
  });

  testWidgets('only the chip of the selected filter is selected',
      (tester) async {
    await tester.pumpWidget(_wrap(_row(selected: MediaFilter.tvOnly)));

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(
      {for (final chip in chips) (chip.label as Text).data: chip.selected},
      {'All 3': false, 'Shows 2': true, 'Films 1': false},
    );
  });

  testWidgets('keeps every chip reachable at 200% text size', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_row(), textScale: 2));

    expect(tester.takeException(), isNull);
    for (final label in ['All 3', 'Shows 2', 'Films 1']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.right, lessThanOrEqualTo(360), reason: label);
    }
  });
}
