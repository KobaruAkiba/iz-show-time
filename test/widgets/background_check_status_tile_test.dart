import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/background/background_task_kind.dart';
import 'package:iz_show_time_tracker/core/background/last_background_check.dart';
import 'package:iz_show_time_tracker/l10n/l10n.dart';
import 'package:iz_show_time_tracker/presentation/screens/settings/background_check_status_tile.dart';

Widget _app(Widget tile) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: tile),
    );

void main() {
  testWidgets('shows a never-run background check', (tester) async {
    await tester.pumpWidget(
      _app(
        BackgroundCheckStatusTile(
          readLastCheck: () async => const LastBackgroundCheckNever(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Last background check'), findsOneWidget);
    expect(find.text('Never run'), findsOneWidget);
  });

  testWidgets('shows the time and kind of the last run', (tester) async {
    await tester.pumpWidget(
      _app(
        BackgroundCheckStatusTile(
          readLastCheck: () async => LastBackgroundCheckAt(
            checkedAt: DateTime(2026, 11, 21, 3, 15),
            taskKind: BackgroundTaskKind.nightly,
          ),
        ),
      ),
    );
    await tester.pump();

    // \s: intl may separate AM with a narrow no-break space.
    expect(
      find.textContaining(RegExp(r'^Nov 21, 2026 3:15\sAM \(nightly\)$')),
      findsOneWidget,
    );
  });

  testWidgets('reads only once the Settings tab is shown', (tester) async {
    var reads = 0;
    Future<LastBackgroundCheck> read() async {
      reads++;
      return const LastBackgroundCheckUnavailable();
    }

    await tester.pumpWidget(
      _app(BackgroundCheckStatusTile(isActive: false, readLastCheck: read)),
    );
    await tester.pump();
    expect(reads, 0);

    await tester.pumpWidget(
      _app(BackgroundCheckStatusTile(readLastCheck: read)),
    );
    await tester.pump();

    expect(reads, 1);
    expect(
      find.text('Not available right now. Reopen Settings to retry.'),
      findsOneWidget,
    );
  });
}
