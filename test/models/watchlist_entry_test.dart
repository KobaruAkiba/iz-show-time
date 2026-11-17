import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';

void main() {
  test('storage json round-trip drops tags and overview, keeps addedAt', () {
    final entry = WatchlistEntry(
      item: const TvShow(
        id: 7,
        title: 'Show',
        overview: 'Long',
        tags: [kFollowedTag, kFavoriteTag],
      ),
      addedAt: DateTime(2026, 11, 17, 9, 30),
    );
    final json = entry.toStorageJson();
    expect(json['added_at'], '2026-11-17T09:30:00.000');
    final restored = WatchlistEntry.fromStorageJson(json);
    expect(restored?.item, isA<TvShow>());
    expect(restored?.mediaKey, 't_7');
    expect(restored?.item.tags, isEmpty);
    expect(restored?.item.overview, isNull);
    expect(restored?.addedAt, DateTime(2026, 11, 17, 9, 30));
  });

  test('fromStorageJson returns null without a valid date or type', () {
    expect(
      WatchlistEntry.fromStorageJson(
          {'type': 'tv', 'id': 1, 'title': 'No date'}),
      isNull,
    );
    expect(
      WatchlistEntry.fromStorageJson(
          {'type': 'tv', 'id': 1, 'title': 'Bad', 'added_at': 'x'}),
      isNull,
    );
    expect(
      WatchlistEntry.fromStorageJson(
          {'type': 'person', 'id': 1, 'added_at': '2026-01-01T00:00:00.000'}),
      isNull,
    );
  });
}
