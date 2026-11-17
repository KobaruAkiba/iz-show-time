import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/services/watchlist_index.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';

void main() {
  final film = WatchlistEntry(
    item: const Film(id: 7, title: 'Film'),
    addedAt: DateTime(2026, 1, 1),
  );
  final show = WatchlistEntry(
    item: const TvShow(id: 7, title: 'Show'),
    addedAt: DateTime(2026, 2, 1),
  );

  test('film and show with the same id are distinct', () {
    final index = WatchlistIndex()..add(film);
    expect(index.contains(const Film(id: 7, title: 'x')), isTrue);
    expect(index.contains(const TvShow(id: 7, title: 'x')), isFalse);
    index.add(show);
    expect(index.addedAtByMediaKey, {
      'm_7': DateTime(2026, 1, 1),
      't_7': DateTime(2026, 2, 1),
    });
  });

  test('add replaces, remove and replaceAll update every view', () {
    final index = WatchlistIndex()..add(film);
    index.add(WatchlistEntry(item: film.item, addedAt: DateTime(2026, 5, 1)));
    expect(index.entries, hasLength(1));
    expect(index.find(film.item)?.addedAt, DateTime(2026, 5, 1));
    index.remove(film.item);
    expect(index.items, isEmpty);
    index.replaceAll([film, show]);
    expect(index.items.map((item) => item.mediaKey), ['m_7', 't_7']);
    expect(() => index.entries.add(film), throwsUnsupportedError);
    index.clear();
    expect(index.addedAtByMediaKey, isEmpty);
  });
}
