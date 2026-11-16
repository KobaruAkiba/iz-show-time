import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:iz_show_time_tracker/core/constants/storage_constants.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/repositories/hive_user_data_store.dart';

/// Box files and backup written by app 1.0.2 (package `hive` 2, schema v2).
/// Do not regenerate them with the current code: they stand for data
/// already on users' devices.
const _fixtureDir = 'test/fixtures/legacy_v1_0_2';

void main() {
  late Directory dir;

  setUp(() {
    // Work on a copy: opening the store migrates the files in place.
    dir = Directory.systemTemp.createTempSync('legacy_storage_');
    for (final file in Directory(_fixtureDir).listSync().whereType<File>()) {
      if (file.path.endsWith('.hive')) {
        file.copySync('${dir.path}/${file.uri.pathSegments.last}');
      }
    }
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  Map<String, dynamic> readLegacyBackup() =>
      jsonDecode(File('$_fixtureDir/backup_v1.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<void> expectLegacyData(HiveUserDataStore store) async {
    final catalogue = await store.loadCatalogue();
    expect(catalogue.map((item) => '${item.mediaKey} ${item.title}').toSet(), {
      'm_550 Fight Club',
      't_1402 The Walking Dead',
      't_1396 Breaking Bad',
    });
    final film = catalogue.firstWhere((item) => item.id == 550);
    expect(film.tags, containsAll(['classic', kFavoriteTag]));
    expect(film.posterPath, '/p.jpg');
    expect(
      catalogue.firstWhere((item) => item.id == 1402).tags,
      contains(kFollowedTag),
    );

    final history = await store.loadWatchHistory();
    expect(
      history.map((record) => record.watchKey).toSet(),
      {'film_550', 'episode_63056'},
    );
    expect(
      history.fold<int>(0, (sum, record) => sum + record.durationMinutes),
      139 + 62,
    );

    expect((await store.loadNewEpisodeAlerts()).single.episodeId, 901);
    expect(await store.loadNotifiedEpisodeIds(), {901, 902});
    expect(await store.loadLastEpisodeCheckAt(), DateTime(2026, 5, 2, 9));
    expect(await store.loadThemeMode(), 'dark');
    expect(await store.loadNotificationPermissionPrePromptShown(), isTrue);
  }

  group('Data saved by app 1.0.2', () {
    test('opens and migrates to the current schema', () async {
      final store = HiveUserDataStore();
      await store.open();

      expect(
        store.metaBox.get(StorageConstants.schemaVersionKey),
        StorageConstants.storageSchemaVersion,
      );
      expect(store.catalogueBox.keys.toSet(), {'m_550', 't_1402', 't_1396'});
      await expectLegacyData(store);

      await store.removeCatalogueItem(
        const TvShow(id: 1396, title: 'Breaking Bad'),
      );
      expect(await store.loadCatalogue(), hasLength(2));
      await store.close();
    });

    test('is still complete after a restart and for background reads',
        () async {
      var store = HiveUserDataStore();
      await store.open();
      await store.flush();
      await store.close();

      store = HiveUserDataStore();
      await store.open();
      await expectLegacyData(store);
      await store.close();

      final snapshot = await HiveUserDataStore.readSnapshot();
      expect(snapshot, isNotNull);
      expect(snapshot!.catalogue, hasLength(3));
      expect(snapshot.watchHistory, hasLength(2));
    });

    test('restores from a backup exported by that version', () async {
      final store = HiveUserDataStore();
      await store.open();
      await store.clearAll();
      expect(await store.loadCatalogue(), isEmpty);

      await store.importBackupData(readLegacyBackup());

      expect(store.catalogueBox.keys.toSet(), {'m_550', 't_1402', 't_1396'});
      await expectLegacyData(store);
      await store.close();
    });
  });
}
