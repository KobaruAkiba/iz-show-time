import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:iz_show_time_tracker/core/constants/storage_constants.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
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
        mediaTitle: film.title,
        isFilm: true,
        durationMinutes: 139,
        watchedAt: DateTime(2026, 1, 15, 20, 30),
      );
      final episodeRecord = WatchRecord(
        mediaId: show.id,
        mediaTitle: show.title,
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

      expect(loadedHistory, hasLength(2));
      expect(
        loadedHistory.map((record) => record.watchKey).toSet(),
        {filmRecord.watchKey, episodeRecord.watchKey},
      );
      expect(loadedHistory.firstWhere((record) => record.isFilm).durationMinutes,
          139);
    });

    test('clearAll removes catalogue and watch history', () async {
      await store.saveCatalogueItem(
        const Film(id: 1, title: 'Test Film'),
      );
      await store.saveWatchRecord(
        WatchRecord(
          mediaId: 1,
          mediaTitle: 'Test Film',
          isFilm: true,
          durationMinutes: 90,
          watchedAt: DateTime(2026, 3, 1),
        ),
      );

      await store.clearAll();

      expect(await store.loadCatalogue(), isEmpty);
      expect(await store.loadWatchHistory(), isEmpty);
      expect(
        store.metaBox.get(StorageConstants.schemaVersionKey),
        StorageConstants.storageSchemaVersion,
      );
    });

    test('removeCatalogueItem and removeWatchRecord delete entries', () async {
      const film = Film(id: 42, title: 'Removed Film');
      final record = WatchRecord(
        mediaId: film.id,
        mediaTitle: film.title,
        isFilm: true,
        durationMinutes: 100,
        watchedAt: DateTime(2026, 4, 1),
      );

      await store.saveCatalogueItem(film);
      await store.saveWatchRecord(record);
      await store.removeCatalogueItem(film.id);
      await store.removeWatchRecord(record.watchKey);

      expect(await store.loadCatalogue(), isEmpty);
      expect(await store.loadWatchHistory(), isEmpty);
    });

    test('stores catalogue values as JSON strings', () async {
      const film = Film(id: 7, title: 'Encoded Film');
      await store.saveCatalogueItem(film);

      final raw = store.catalogueBox.get(film.id);
      expect(raw, isA<String>());
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
      expect(catalogueItemFromStorageJson({'id': 1, 'title': 'No type'}), isNull);
      expect(
        catalogueItemFromStorageJson({'type': 'person', 'id': 2, 'name': 'Actor'}),
        isNull,
      );
    });
  });

  group('catalogueItemToStorageJson', () {
    test('includes type discriminator', () {
      final json = catalogueItemToStorageJson(
        const Film(id: 10, title: 'Inception'),
      );

      expect(json['type'], 'film');
      expect(json['title'], 'Inception');
    });
  });
}
