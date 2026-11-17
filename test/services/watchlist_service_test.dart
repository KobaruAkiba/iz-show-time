import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/watchlist_service.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';
import 'package:iz_show_time_tracker/data/repositories/watchlist_store.dart';

class _FakeWatchlistStore implements WatchlistStore {
  final Map<String, WatchlistEntry> entries = {};
  int saveCount = 0;
  final List<String> removed = [];

  @override
  Future<List<WatchlistEntry>> loadWatchlist() async => entries.values.toList();

  @override
  Future<void> saveWatchlistEntry(WatchlistEntry e) async {
    saveCount++;
    entries[e.mediaKey] = e;
  }

  @override
  Future<void> removeWatchlistEntry(String mediaKey) async {
    removed.add(mediaKey);
    entries.remove(mediaKey);
  }
}

void main() {
  late _FakeWatchlistStore store;
  late Set<String> catalogued;
  late int flushCount;
  late WatchlistService service;
  const show = TvShow(id: 7, title: 'Show', tags: [kFollowedTag]);
  final now = DateTime(2026, 11, 17, 9);

  setUp(() {
    store = _FakeWatchlistStore();
    catalogued = {};
    flushCount = 0;
    service = WatchlistService(
      store: () => store,
      flushIfIdle: () async => flushCount++,
      isInCatalogue: (item) => catalogued.contains(item.mediaKey),
      clock: () => now,
    );
  });

  test('add stores a tagless entry, persists it and flushes', () async {
    expect(await service.add(show), WatchlistAddResult.added);
    expect(service.entries.single.addedAt, now);
    expect(service.entries.single.item.tags, isEmpty);
    expect(store.entries.keys, ['t_7']);
    expect(flushCount, 1);
    expect(service.listenable.value, hasLength(1));
  });

  test('add refuses a catalogued title', () async {
    catalogued.add('t_7');
    expect(await service.add(show), WatchlistAddResult.alreadyInCatalogue);
    expect(service.entries, isEmpty);
    expect(store.saveCount, 0);
  });

  // Review Focus 4
  test('a double tap adds the title only once', () async {
    final results = await Future.wait([service.add(show), service.add(show)]);
    expect(
      results.toSet(),
      {WatchlistAddResult.added, WatchlistAddResult.alreadyPresent},
    );
    expect(store.saveCount, 1);
  });

  test('remove reports whether the entry existed', () async {
    await service.add(show);
    expect(await service.remove(show), isTrue);
    expect(await service.remove(show), isFalse);
    expect(store.removed, ['t_7']);
  });

  test('restore keeps the original addedAt', () async {
    await service.add(show);
    final entry = service.entryFor(show);
    await service.remove(show);
    await service.restore(entry!); // test-only: entry was just added
    expect(service.addedAtByMediaKey['t_7'], now);
    expect(store.entries.containsKey('t_7'), isTrue);
  });

  // Review Focus 2
  test('restore is ignored once the title is in the catalogue', () async {
    catalogued.add('t_7');
    await service.restore(WatchlistEntry(item: show, addedAt: now));
    expect(service.contains(show), isFalse);
    expect(store.saveCount, 0);
  });

  test('loadFrom drops entries already in the catalogue', () async {
    store.entries['t_7'] = WatchlistEntry(item: show, addedAt: now);
    store.entries['m_8'] = WatchlistEntry(
      item: const Film(id: 8, title: 'Film'),
      addedAt: now,
    );
    catalogued.add('t_7');
    await service.loadFrom(store);
    expect(service.entries.map((e) => e.mediaKey), ['m_8']);
    expect(store.removed, ['t_7']);
  });

  test('clear empties memory and notifies, leaving the store alone', () async {
    await service.add(show);
    service.clear();
    expect(service.listenable.value, isEmpty);
    expect(store.entries, hasLength(1));
  });
}
