import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/bookmark_only_shows_migration.dart';
import 'package:iz_show_time_tracker/core/services/catalogue_index.dart';
import 'package:iz_show_time_tracker/core/services/watch_history_index.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';

import '../support/fake_user_data_store.dart';

void main() {
  late FakeUserDataStore store;
  late CatalogueIndex catalogue;
  late WatchHistoryIndex history;
  final now = DateTime(2026, 11, 17);
  const film = Film(id: 1, title: 'Film');
  const bookmarked = TvShow(
    id: 2,
    title: 'Bookmarked',
    tags: [kFollowedTag, kFavoriteTag],
  );
  const watching = TvShow(id: 3, title: 'Watching');

  BookmarkOnlyShowsMigration migration() => BookmarkOnlyShowsMigration(
        store: store,
        catalogue: catalogue,
        history: history,
        clock: () => now,
      );

  setUp(() {
    store = FakeUserDataStore()..catalogue.addAll([film, bookmarked, watching]);
    catalogue = CatalogueIndex()..replaceAll([film, bookmarked, watching]);
    history = WatchHistoryIndex()
      ..add(
        WatchRecord(
          mediaId: 3,
          isFilm: false,
          episodeId: 301,
          seasonNumber: 1,
          episodeNumber: 1,
          durationMinutes: 40,
          watchedAt: DateTime(2026, 1, 1),
        ),
      );
  });

  test('moves only shows without watched episodes, dropping their tags',
      () async {
    expect(await migration().run(), 1);
    expect(catalogue.items.map((i) => i.mediaKey), ['m_1', 't_3']);
    expect(store.catalogue.map((i) => i.mediaKey), ['m_1', 't_3']);
    expect(store.watchlist.single.mediaKey, 't_2');
    expect(store.watchlist.single.item.tags, isEmpty);
    expect(store.watchlist.single.addedAt, now);
    expect(store.watchlistMigrationDone, isTrue);
  });

  test('uses the last known activity as addedAt', () async {
    history.add(
      WatchRecord(
        mediaId: 2,
        isFilm: false,
        durationMinutes: 0,
        watchedAt: DateTime(2026, 3, 1),
      ),
    );
    await migration().run();
    expect(store.watchlist.single.addedAt, DateTime(2026, 3, 1));
  });

  test('does nothing once the flag is set', () async {
    store.watchlistMigrationDone = true;
    expect(await migration().run(), 0);
    expect(catalogue.items, hasLength(3));
    expect(store.watchlist, isEmpty);
  });
}
