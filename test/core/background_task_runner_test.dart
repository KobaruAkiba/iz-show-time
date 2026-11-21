import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/background/background_task_runner.dart';
import 'package:iz_show_time_tracker/core/constants/app_constants.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

class _OfflineTrendingTmdbService extends TmdbService {
  _OfflineTrendingTmdbService() : super(cacheManager: null);

  @override
  Future<List<CatalogueItem>> getTrendingAll({
    bool forceRefresh = false,
  }) async =>
      const [];
}

/// Lets the unawaited cycle started by [BackgroundTaskRunner.start] finish.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late DateTime now;
  late int refreshCount;
  late BackgroundTaskRunner runner;

  setUp(() {
    now = DateTime(2026, 11, 21, 10);
    refreshCount = 0;
    runner = BackgroundTaskRunner.withClock(() => now);
  });

  tearDown(() => runner.stop());

  Future<void> start({Future<void> Function()? onRefresh}) async {
    await runner.start(
      tmdbService: _OfflineTrendingTmdbService(),
      onForegroundRefresh: onRefresh ?? () async => refreshCount++,
    );
    await _settle();
  }

  group('BackgroundTaskRunner.onAppResumed', () {
    test('is a no-op before start', () async {
      await runner.onAppResumed();

      expect(refreshCount, 0);
    });

    test('skips the refresh when the last cycle is recent', () async {
      await start();
      expect(refreshCount, 1);

      now = now.add(
        AppConstants.resumeRefreshMinInterval - const Duration(minutes: 1),
      );
      await runner.onAppResumed();

      expect(refreshCount, 1);
    });

    test('refreshes once the last cycle is older than the threshold', () async {
      await start();

      now = now.add(AppConstants.resumeRefreshMinInterval);
      await runner.onAppResumed();

      expect(refreshCount, 2);
    });

    test('measures the threshold from the latest cycle', () async {
      await start();
      now = now.add(AppConstants.resumeRefreshMinInterval);
      await runner.onAppResumed();

      now = now.add(const Duration(minutes: 1));
      await runner.onAppResumed();

      expect(refreshCount, 2);
    });

    test('does not overlap a cycle still in progress', () async {
      final release = Completer<void>();
      await start(
        onRefresh: () async {
          refreshCount++;
          await release.future;
        },
      );

      now = now.add(const Duration(hours: 1));
      await runner.onAppResumed();
      expect(refreshCount, 1);

      release.complete();
    });

    test('is a no-op again after stop', () async {
      await start();
      runner.stop();

      now = now.add(const Duration(hours: 1));
      await runner.onAppResumed();

      expect(refreshCount, 1);
    });
  });
}
