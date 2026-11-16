import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:iz_show_time_tracker/core/cache/cache_manager.dart';
import 'package:iz_show_time_tracker/core/cache/tmdb_disk_cache.dart';
import 'package:iz_show_time_tracker/core/constants/api_constants.dart';
import 'package:iz_show_time_tracker/core/network/dio_client.dart';
import 'package:iz_show_time_tracker/data/services/tmdb_service.dart';

/// Serves one show payload while [online]; fails the connection otherwise.
class _ToggleAdapter implements HttpClientAdapter {
  bool online = true;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    if (!online) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'id': 7, 'number_of_seasons': 3}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late TmdbDiskCache diskCache;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('tmdb_disk_cache_test_');
    Hive.init(tempDir.path);
    diskCache = await TmdbDiskCache.open();
  });

  tearDown(() async {
    await diskCache.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('TmdbDiskCache', () {
    test('round-trips a payload with its expiry', () async {
      await diskCache.write('tv/1', {'name': 'Show'}, ttlMinutes: 60);

      final entry = await diskCache.read('tv/1');

      expect(entry!.value, {'name': 'Show'});
      expect(entry.isExpired, isFalse);
      expect(await diskCache.read('tv/2'), isNull);
    });

    test('keeps expired entries readable and flags them', () async {
      await diskCache.write('tv/1', {'name': 'Show'}, ttlMinutes: -1);

      final entry = await diskCache.read('tv/1');

      expect(entry!.isExpired, isTrue);
      expect(entry.value, {'name': 'Show'});
    });

    test('trim drops the entries that expire first', () async {
      for (var index = 1; index <= 5; index++) {
        await diskCache.write('tv/$index', {'id': index}, ttlMinutes: index);
      }

      await diskCache.trim(maxEntries: 2);

      expect(diskCache.length, 2);
      expect(await diskCache.read('tv/1'), isNull);
      expect((await diskCache.read('tv/5'))!.value, {'id': 5});
    });

    test('clear removes everything', () async {
      await diskCache.write('tv/1', {'name': 'Show'}, ttlMinutes: 60);

      await diskCache.clear();

      expect(diskCache.length, 0);
    });
  });

  group('TmdbService with a disk cache', () {
    late _ToggleAdapter adapter;

    setUp(() {
      AppApiKey.configure('test-key');
      DioClient.connectionRetryDelays = const [];
      adapter = _ToggleAdapter();
      DioClient.httpClientAdapter = adapter;
      CacheManager().clearAll();
    });

    tearDown(() => AppApiKey.configure(''));

    TmdbService service() =>
        TmdbService(cacheManager: CacheManager(), diskCache: diskCache);

    test('a restart reads the payload from disk instead of the network',
        () async {
      expect((await service().getTvShowSummary(7))!.numberOfSeasons, 3);
      // The disk write is not awaited by the service.
      await pumpEventQueue();
      CacheManager().clearAll();

      final summary = await service().getTvShowSummary(7);

      expect(summary!.numberOfSeasons, 3);
      expect(adapter.requestCount, 1);
    });

    test('serves the stored copy when a forced refresh fails offline',
        () async {
      await service().getTvShowSummary(7);
      await pumpEventQueue();
      CacheManager().clearAll();
      adapter.online = false;

      final summary = await service().getTvShowSummary(7, forceRefresh: true);

      expect(summary!.numberOfSeasons, 3);
      expect(adapter.requestCount, 2);
    });

    test('still fails offline when nothing is stored', () async {
      adapter.online = false;

      await expectLater(
        service().getTvShowSummary(7),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
