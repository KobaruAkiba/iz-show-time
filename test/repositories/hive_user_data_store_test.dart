import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:iz_show_time_tracker/core/constants/storage_constants.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';
import 'package:iz_show_time_tracker/data/repositories/background_check_outbox.dart';
import 'package:iz_show_time_tracker/data/repositories/hive_user_data_store.dart';

void main() {
  late Directory tempDir;
  late HiveUserDataStore store;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_user_data_store_test_');
    Hive.init(tempDir.path);
    store = HiveUserDataStore();
    await store.open();
  });

  tearDown(() async {
    await store.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HiveUserDataStore', () {
    test('round-trips watchlist entries and clearAll removes them', () async {
      final film = WatchlistEntry(
        item: const Film(id: 7, title: 'Film'),
        addedAt: DateTime(2026, 1, 1),
      );
      final show = WatchlistEntry(
        item: const TvShow(id: 7, title: 'Show'),
        addedAt: DateTime(2026, 2, 1),
      );
      await store.saveWatchlistEntry(film);
      await store.saveWatchlistEntry(show);
      expect(store.watchlistBox.keys.toSet(), {'m_7', 't_7'});
      expect(store.watchlistBox.get('t_7'), isA<String>());

      await store.removeWatchlistEntry('m_7');
      expect(
          (await store.loadWatchlist()).single.addedAt, DateTime(2026, 2, 1));

      await store.clearAll();
      expect(await store.loadWatchlist(), isEmpty);
    });

    test('persists the watchlist migration flag', () async {
      expect(await store.loadWatchlistMigrationDone(), isFalse);
      await store.saveWatchlistMigrationDone();
      expect(await store.loadWatchlistMigrationDone(), isTrue);
      expect(
        store.metaBox.get(StorageConstants.watchlistMigrationV1DoneKey),
        isTrue,
      );
    });

    test('readSnapshot never opens the watchlist box', () async {
      await store.close();
      await Hive.deleteBoxFromDisk(StorageConstants.watchlistBoxName);

      await HiveUserDataStore.readSnapshot();

      expect(File('${tempDir.path}/watchlist.hive').existsSync(), isFalse);
    });

    test('round-trips catalogue items and watch records', () async {
      const film = Film(
        id: 550,
        title: 'Fight Club',
        overview: 'An insomniac office worker...',
        posterPath: '/poster.jpg',
        voteAverage: 8.4,
        tags: ['classic'],
      );
      const show = TvShow(
        id: 1399,
        title: 'Game of Thrones',
        overview: 'Nine noble families...',
        posterPath: '/got.jpg',
        voteAverage: 8.5,
      );
      final filmRecord = WatchRecord(
        mediaId: film.id,
        isFilm: true,
        durationMinutes: 139,
        watchedAt: DateTime(2026, 1, 15, 20, 30),
      );
      final episodeRecord = WatchRecord(
        mediaId: show.id,
        isFilm: false,
        episodeId: 63056,
        seasonNumber: 1,
        episodeNumber: 1,
        durationMinutes: 62,
        watchedAt: DateTime(2026, 2, 1, 21, 0),
      );

      await store.saveCatalogueItem(film);
      await store.saveCatalogueItem(show);
      await store.saveWatchRecord(filmRecord);
      await store.saveWatchRecord(episodeRecord);

      final loadedCatalogue = await store.loadCatalogue();
      final loadedHistory = await store.loadWatchHistory();

      expect(loadedCatalogue, hasLength(2));
      expect(loadedCatalogue.whereType<Film>(), hasLength(1));
      expect(loadedCatalogue.whereType<TvShow>(), hasLength(1));
      expect(loadedCatalogue.firstWhere((item) => item.id == 550).title,
          'Fight Club');
      expect(
        loadedCatalogue.firstWhere((item) => item.id == 550).tags,
        ['classic'],
      );
      expect(loadedCatalogue.firstWhere((item) => item.id == 550).overview,
          isNull);
      final rawFilm = store.catalogueBox.get(film.mediaKey) as String;
      expect(rawFilm.contains('overview'), isFalse);
      final rawWatch = store.watchHistoryBox.get(filmRecord.watchKey) as String;
      expect(rawWatch.contains('media_title'), isFalse);

      expect(loadedHistory, hasLength(2));
      expect(
        loadedHistory.map((record) => record.watchKey).toSet(),
        {filmRecord.watchKey, episodeRecord.watchKey},
      );
      expect(
          loadedHistory.firstWhere((record) => record.isFilm).durationMinutes,
          139);
    });

    test('clearAll removes catalogue and watch history', () async {
      await store.saveCatalogueItem(
        const Film(id: 1, title: 'Test Film'),
      );
      await store.saveWatchRecord(
        WatchRecord(
          mediaId: 1,
          isFilm: true,
          durationMinutes: 90,
          watchedAt: DateTime(2026, 3, 1),
        ),
      );
      await store.saveNewEpisodeAlerts([
        NewEpisodeAlert(
          showId: 1,
          showTitle: 'Test Film',
          episodeId: 11,
          seasonNumber: 1,
          episodeNumber: 2,
          episodeName: 'Episode 2',
          detectedAt: DateTime(2026, 3, 2),
        ),
      ]);

      await store.clearAll();

      expect(await store.loadCatalogue(), isEmpty);
      expect(await store.loadWatchHistory(), isEmpty);
      expect(await store.loadNewEpisodeAlerts(), isEmpty);
      expect(
        store.metaBox.get(StorageConstants.schemaVersionKey),
        StorageConstants.storageSchemaVersion,
      );
    });

    test('round-trips new episode alerts', () async {
      final checkedAt = DateTime(2026, 5, 1, 12);
      final detectedAt = DateTime(2026, 5, 2, 8);

      await store.saveNewEpisodeAlerts([
        NewEpisodeAlert(
          showId: 42,
          showTitle: 'Sample Show',
          showPosterPath: '/poster.jpg',
          episodeId: 901,
          seasonNumber: 3,
          episodeNumber: 9,
          episodeName: 'New One',
          airDate: DateTime(2026, 5, 1),
          detectedAt: detectedAt,
        ),
      ]);
      await store.saveLastEpisodeCheckAt(checkedAt);

      final alerts = await store.loadNewEpisodeAlerts();
      final lastCheck = await store.loadLastEpisodeCheckAt();

      expect(alerts, hasLength(1));
      expect(alerts.first.episodeName, 'New One');
      expect(lastCheck, checkedAt);
    });

    test('persists notification permission pre-prompt flag', () async {
      expect(await store.loadNotificationPermissionPrePromptShown(), isFalse);

      await store.saveNotificationPermissionPrePromptShown(true);
      expect(await store.loadNotificationPermissionPrePromptShown(), isTrue);

      await store.clearAll();
      expect(await store.loadNotificationPermissionPrePromptShown(), isFalse);
    });

    test('persists theme mode and keeps it across clearAll', () async {
      expect(await store.loadThemeMode(), isNull);

      await store.saveThemeMode('dark');
      expect(await store.loadThemeMode(), 'dark');

      await store.clearAll();
      expect(await store.loadThemeMode(), 'dark');
    });

    test('persists hide watch time and keeps it across clearAll', () async {
      expect(await store.loadHideWatchTime(), isFalse);

      await store.saveHideWatchTime(true);
      expect(await store.loadHideWatchTime(), isTrue);

      await store.clearAll();
      expect(await store.loadHideWatchTime(), isTrue);
    });

    test('removeCatalogueItem and removeWatchRecord delete entries', () async {
      const film = Film(id: 42, title: 'Removed Film');
      final record = WatchRecord(
        mediaId: film.id,
        isFilm: true,
        durationMinutes: 100,
        watchedAt: DateTime(2026, 4, 1),
      );

      await store.saveCatalogueItem(film);
      await store.saveWatchRecord(record);
      await store.removeCatalogueItem(film);
      await store.removeWatchRecord(record.watchKey);
      await store.flush();

      expect(await store.loadCatalogue(), isEmpty);
      expect(await store.loadWatchHistory(), isEmpty);
    });

    test('saveWatchRecords and removeWatchRecords batch round-trip', () async {
      final records = List.generate(
        50,
        (index) => WatchRecord(
          mediaId: 1000,
          isFilm: false,
          episodeId: 5000 + index,
          seasonNumber: 1,
          episodeNumber: index + 1,
          durationMinutes: 42,
          watchedAt: DateTime(2026, 1, 1),
        ),
      );

      await store.saveWatchRecords(records);
      await store.flush();

      final loaded = await store.loadWatchHistory();
      expect(loaded, hasLength(50));

      await store.removeWatchRecords(records.map((record) => record.watchKey));
      await store.flush();

      expect(await store.loadWatchHistory(), isEmpty);
    });

    test('stores catalogue values as JSON strings', () async {
      const film = Film(id: 7, title: 'Encoded Film');
      await store.saveCatalogueItem(film);

      final raw = store.catalogueBox.get(film.mediaKey);
      expect(raw, isA<String>());
    });

    test('keeps a film and a TV show that share a TMDB id', () async {
      const film = Film(id: 1402, title: 'Same Id Film');
      const show = TvShow(id: 1402, title: 'Same Id Show');

      await store.saveCatalogueItem(show);
      await store.saveCatalogueItem(film);

      expect(await store.loadCatalogue(), hasLength(2));

      await store.removeCatalogueItem(film);

      final remaining = await store.loadCatalogue();
      expect(remaining.single, isA<TvShow>());
    });

    test('migrates bare-id catalogue keys to media keys (schema v3)',
        () async {
      await store.catalogueBox.put(
        1402,
        jsonEncode({'type': 'tv', 'id': 1402, 'name': 'Legacy Show'}),
      );
      await store.catalogueBox.put(
        550,
        jsonEncode({'type': 'film', 'id': 550, 'title': 'Legacy Film'}),
      );
      await store.metaBox.put(StorageConstants.schemaVersionKey, 2);
      await store.flush();
      await store.close();

      store = HiveUserDataStore();
      await store.open();

      expect(store.catalogueBox.keys.toSet(), {'t_1402', 'm_550'});
      expect(
        store.metaBox.get(StorageConstants.schemaVersionKey),
        StorageConstants.storageSchemaVersion,
      );
      final loaded = await store.loadCatalogue();
      expect(loaded.map((item) => item.title).toSet(),
          {'Legacy Show', 'Legacy Film'});
    });

    test('readSnapshot copies user data without owning the boxes', () async {
      const show = TvShow(id: 9, title: 'Snapshot Show', tags: [kFollowedTag]);
      await store.saveCatalogueItem(show);
      await store.saveAppInForeground(true);
      await store.saveNotifiedEpisodeIds({5, 6});
      await store.flush();
      await store.close();

      final snapshot = await HiveUserDataStore.readSnapshot();

      expect(snapshot, isNotNull);
      expect(snapshot!.catalogue.single.title, 'Snapshot Show');
      expect(snapshot.appInForeground, isTrue);
      expect(snapshot.notifiedEpisodeIds, {5, 6});
      expect(Hive.isBoxOpen(StorageConstants.catalogueBoxName), isFalse);
    });

    test('saving the foreground flag writes a heartbeat', () async {
      await store.saveAppInForeground(true);

      final heartbeatAt = await store.loadAppForegroundHeartbeatAt();
      expect(heartbeatAt, isNotNull);
      expect(
        DateTime.now().difference(heartbeatAt!).abs(),
        lessThan(const Duration(seconds: 5)),
      );

      await store.flush();
      await store.close();
      final snapshot = await HiveUserDataStore.readSnapshot();
      expect(snapshot!.appForegroundHeartbeatAt, heartbeatAt);
    });

    test('clearAll removes the foreground heartbeat', () async {
      await store.saveAppInForeground(true);
      await store.clearAll();

      expect(await store.loadAppForegroundHeartbeatAt(), isNull);
    });

    test('readSnapshot leaves an outdated schema to the owner', () async {
      await store.catalogueBox.put(
        3,
        jsonEncode({'type': 'film', 'id': 3, 'title': 'Legacy'}),
      );
      await store.metaBox.put(StorageConstants.schemaVersionKey, 2);
      await store.flush();
      await store.close();

      expect(await HiveUserDataStore.readSnapshot(), isNull);

      await store.open();
      expect(store.catalogueBox.keys.toList(), ['m_3']);
    });

    test('background check outbox round-trips and is cleared with the data',
        () async {
      expect(await store.loadBackgroundCheckResult(), isNull);

      final outbox = await BackgroundCheckOutbox.openForWriting();
      expect(outbox.notifiedEpisodeIds, isNull);
      await outbox.save(
        alerts: [
          NewEpisodeAlert(
            showId: 42,
            showTitle: 'Sample Show',
            episodeId: 901,
            seasonNumber: 3,
            episodeNumber: 9,
            episodeName: 'New One',
            detectedAt: DateTime(2026, 5, 2, 8),
          ),
        ],
        checkedAt: DateTime(2026, 5, 2, 9),
        notifiedEpisodeIds: {901},
      );
      await outbox.close();

      final result = await store.loadBackgroundCheckResult();
      expect(result!.checkedAt, DateTime(2026, 5, 2, 9));
      expect(result.alerts.single.episodeId, 901);
      expect(Hive.isBoxOpen(BackgroundCheckOutbox.boxName), isFalse);

      final reopened = await BackgroundCheckOutbox.openForWriting();
      expect(reopened.notifiedEpisodeIds, {901});
      await reopened.close();

      await store.clearAll();
      expect(await store.loadBackgroundCheckResult(), isNull);
    });

    test('rejects a backup with unreadable entries and keeps current data',
        () async {
      await store.saveCatalogueItem(const Film(id: 5, title: 'Kept Film'));
      await store.saveThemeMode('dark');

      Future<void> importWith({
        required Map<String, dynamic> catalogue,
        required Map<String, dynamic> watchHistory,
      }) {
        return store.importBackupData({
          'format': 'iz_show_time_backup',
          'version': 2,
          'catalogue': catalogue,
          'watchHistory': watchHistory,
          'meta': <String, dynamic>{},
        });
      }

      await expectLater(
        importWith(
          catalogue: {'m_1': jsonEncode({'type': 'person', 'id': 1})},
          watchHistory: {},
        ),
        throwsFormatException,
      );
      await expectLater(
        importWith(
          catalogue: {},
          watchHistory: {'film_1': jsonEncode({'media_id': 'not a number'})},
        ),
        throwsFormatException,
      );

      expect((await store.loadCatalogue()).single.title, 'Kept Film');
      expect(await store.loadThemeMode(), 'dark');
    });

    test('imports a version 1 backup keyed by bare id', () async {
      await store.importBackupData({
        'format': 'iz_show_time_backup',
        'version': 1,
        'catalogue': {
          '550': jsonEncode({'type': 'film', 'id': 550, 'title': 'Old Film'}),
        },
        'watchHistory': <String, dynamic>{},
        'meta': <String, dynamic>{},
      });

      expect(store.catalogueBox.keys.toList(), ['m_550']);
      expect((await store.loadCatalogue()).single.title, 'Old Film');
    });

    test('exports and imports portable backup payloads', () async {
      const show = TvShow(
        id: 101,
        title: 'Portable Show',
        posterPath: '/portable.jpg',
        voteAverage: 7.8,
        tags: [kFollowedTag],
      );
      final record = WatchRecord(
        mediaId: show.id,
        isFilm: false,
        episodeId: 2001,
        seasonNumber: 1,
        episodeNumber: 1,
        durationMinutes: 44,
        watchedAt: DateTime(2026, 2, 2, 20),
      );
      final alert = NewEpisodeAlert(
        showId: show.id,
        showTitle: show.title,
        episodeId: 2002,
        seasonNumber: 1,
        episodeNumber: 2,
        episodeName: 'Episode 2',
        detectedAt: DateTime(2026, 2, 3, 8),
      );

      await store.saveCatalogueItem(show);
      await store.saveWatchRecord(record);
      await store.saveNewEpisodeAlerts([alert]);
      await store.saveThemeMode('dark');
      await store.saveHideWatchTime(true);
      await store.saveAppInForeground(true);
      await store.saveLastTmdbCachePurgeAt(DateTime(2026, 2, 1).toUtc());
      await store.flush();

      final backup = await store.exportBackupData();
      final backupMeta = Map<String, dynamic>.from(backup['meta'] as Map);

      expect(backupMeta[StorageConstants.hideWatchTimeKey], isTrue);

      expect(
        backupMeta.containsKey(StorageConstants.appInForegroundKey),
        isFalse,
      );
      expect(
        backupMeta.containsKey(StorageConstants.appForegroundHeartbeatAtKey),
        isFalse,
      );
      expect(
        backupMeta.containsKey(StorageConstants.lastTmdbCachePurgeKey),
        isFalse,
      );

      await store.clearAll();
      await store.importBackupData(backup);

      expect(await store.loadCatalogue(), hasLength(1));
      expect(await store.loadWatchHistory(), hasLength(1));
      expect(await store.loadNewEpisodeAlerts(), hasLength(1));
      expect(await store.loadThemeMode(), 'dark');
      expect(await store.loadHideWatchTime(), isTrue);
    });

    test('migrates legacy bulky payloads to schema v2', () async {
      await store.catalogueBox.put(
        1,
        jsonEncode({
          'type': 'film',
          'id': 1,
          'title': 'Legacy',
          'overview': 'Huge overview text that should be dropped',
          'poster_path': '/x.jpg',
          'vote_average': 1.0,
          'tags': <String>[],
        }),
      );
      await store.watchHistoryBox.put(
        'film_1',
        jsonEncode({
          'media_id': 1,
          'media_title': 'Legacy',
          'is_film': true,
          'duration_minutes': 90,
          'watched_at': '2026-01-01T00:00:00.000',
        }),
      );
      await store.metaBox.put(StorageConstants.schemaVersionKey, 1);
      await store.flush();
      await store.close();

      store = HiveUserDataStore();
      await store.open();

      final catalogueRaw = store.catalogueBox.get('m_1') as String;
      expect(catalogueRaw.contains('overview'), isFalse);
      final watchRaw = store.watchHistoryBox.get('film_1') as String;
      expect(watchRaw.contains('media_title'), isFalse);
      expect(
        store.metaBox.get(StorageConstants.schemaVersionKey),
        StorageConstants.storageSchemaVersion,
      );

      final loaded = await store.loadCatalogue();
      expect(loaded.single.overview, isNull);
      expect(loaded.single.title, 'Legacy');
    });
  });

  group('HiveUserDataStore watchlist backup', () {
    WatchlistEntry entry(int id, String title) => WatchlistEntry(
          item: TvShow(id: id, title: title),
          addedAt: DateTime(2026, 3, 1, 8),
        );
    Map<String, dynamic> backupWith({
      Map<String, dynamic> catalogue = const {},
      Object? watchlist,
    }) =>
        {
          'format': 'iz_show_time_backup',
          'version': 2,
          'catalogue': catalogue,
          'watchHistory': <String, dynamic>{},
          'meta': <String, dynamic>{},
          if (watchlist != null) 'watchlist': watchlist,
        };

    test('backup round-trips the watchlist and keeps version 2', () async {
      await store.saveWatchlistEntry(entry(7, 'Saved Show'));
      final backup = await store.exportBackupData();
      expect(backup['version'], 2);
      expect((backup['watchlist'] as Map).keys, ['t_7']);

      await store.clearAll();
      await store.importBackupData(backup);

      final loaded = await store.loadWatchlist();
      expect(loaded.single.item.title, 'Saved Show');
      expect(loaded.single.addedAt, DateTime(2026, 3, 1, 8));
    });

    test('a backup without a watchlist section imports an empty watchlist',
        () async {
      await store.saveWatchlistEntry(entry(7, 'Old'));
      await store.importBackupData(backupWith());
      expect(await store.loadWatchlist(), isEmpty);
    });

    test('import resets the watchlist migration flag', () async {
      await store.saveWatchlistMigrationDone();
      final backup = await store.exportBackupData();
      expect(
        (backup['meta'] as Map)
            .containsKey(StorageConstants.watchlistMigrationV1DoneKey),
        isFalse,
      );
      await store.importBackupData(backup);
      expect(await store.loadWatchlistMigrationDone(), isFalse);
    });

    // Review Focus 3
    test('rejects an invalid watchlist section and keeps current data',
        () async {
      await store.saveCatalogueItem(const Film(id: 5, title: 'Kept Film'));
      await store.saveWatchlistEntry(entry(7, 'Kept Show'));
      await expectLater(
        store.importBackupData(backupWith(watchlist: ['not a map'])),
        throwsFormatException,
      );
      await expectLater(
        store.importBackupData(backupWith(watchlist: {
          't_1': jsonEncode({'type': 'tv', 'id': 1, 'title': 'No date'}),
        })),
        throwsFormatException,
      );

      expect((await store.loadCatalogue()).single.title, 'Kept Film');
      expect((await store.loadWatchlist()).single.item.title, 'Kept Show');
    });

    test('a failing watchlist write rolls the whole import back', () async {
      await store.saveCatalogueItem(const Film(id: 5, title: 'Kept Film'));
      await store.saveWatchlistEntry(entry(7, 'Kept Show'));

      await expectLater(
        store.importBackupData(backupWith(
          catalogue: {
            'm_9': jsonEncode({'type': 'film', 'id': 9, 'title': 'Imported'}),
          },
          // Hive rejects String keys longer than 255 characters.
          watchlist: {
            'k' * 256: jsonEncode(entry(8, 'Bad key').toStorageJson()),
          },
        )),
        throwsA(isA<HiveError>()),
      );

      expect((await store.loadCatalogue()).single.title, 'Kept Film');
      expect((await store.loadWatchlist()).single.item.title, 'Kept Show');
    });
  });

  group('catalogueItemFromStorageJson', () {
    test('restores film and tv entries', () {
      final film = catalogueItemFromStorageJson({
        'type': 'film',
        'id': 1,
        'title': 'Film',
        'tags': ['a'],
      });
      final show = catalogueItemFromStorageJson({
        'type': 'tv',
        'id': 2,
        'name': 'Show',
      });

      expect(film, isA<Film>());
      expect(show, isA<TvShow>());
      expect(film?.tags, ['a']);
    });

    test('returns null for missing or invalid type', () {
      expect(
          catalogueItemFromStorageJson({'id': 1, 'title': 'No type'}), isNull);
      expect(
        catalogueItemFromStorageJson(
            {'type': 'person', 'id': 2, 'name': 'Actor'}),
        isNull,
      );
    });
    test('ignores legacy overview on restore', () {
      final film = catalogueItemFromStorageJson({
        'type': 'film',
        'id': 1,
        'title': 'Film',
        'overview': 'Should be dropped',
        'tags': ['a'],
      });

      expect(film, isA<Film>());
      expect(film?.overview, isNull);
    });
  });

  group('catalogueItemToStorageJson', () {
    test('includes type discriminator and omits overview', () {
      final json = catalogueItemToStorageJson(
        const Film(
          id: 10,
          title: 'Inception',
          overview: 'A thief who steals corporate secrets...',
        ),
      );

      expect(json['type'], 'film');
      expect(json['title'], 'Inception');
      expect(json.containsKey('overview'), isFalse);
    });
  });

  group('catalogueItemForLocalStore', () {
    test('drops overview while keeping list fields', () {
      const film = Film(
        id: 1,
        title: 'Test',
        overview: 'Long text',
        posterPath: '/p.jpg',
        voteAverage: 7.5,
        tags: [kFavoriteTag],
      );

      final trimmed = catalogueItemForLocalStore(film) as Film;
      expect(trimmed.overview, isNull);
      expect(trimmed.posterPath, '/p.jpg');
      expect(trimmed.tags, [kFavoriteTag]);
    });
  });
}
