import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/utils/duration_format.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';

void main() {
  group('formatDurationMinutes', () {
    test('formats minutes only', () {
      expect(formatDurationMinutes(45), '45m');
    });

    test('formats hours only', () {
      expect(formatDurationMinutes(120), '2h');
    });

    test('formats hours and minutes', () {
      expect(formatDurationMinutes(135), '2h 15m');
    });

    test('handles zero', () {
      expect(formatDurationMinutes(0), '0m');
    });
  });

  group('WatchRecord', () {
    test('uses film key for movies', () {
      final record = WatchRecord(
        mediaId: 550,
        mediaTitle: 'Fight Club',
        isFilm: true,
        durationMinutes: 139,
        watchedAt: DateTime(2024, 1, 1),
      );

      expect(record.watchKey, 'film_550');
    });

    test('uses episode id for TV episodes', () {
      final record = WatchRecord(
        mediaId: 1399,
        mediaTitle: 'Game of Thrones',
        isFilm: false,
        episodeId: 63056,
        seasonNumber: 1,
        episodeNumber: 1,
        durationMinutes: 62,
        watchedAt: DateTime(2024, 1, 1),
      );

      expect(record.watchKey, 'episode_63056');
    });

    test('round-trips through JSON', () {
      final original = WatchRecord(
        mediaId: 1399,
        mediaTitle: 'Game of Thrones',
        isFilm: false,
        episodeId: 63056,
        seasonNumber: 1,
        episodeNumber: 1,
        durationMinutes: 62,
        watchedAt: DateTime(2024, 6, 1, 12, 30),
      );

      final restored = WatchRecord.fromJson(original.toJson());

      expect(restored.mediaId, original.mediaId);
      expect(restored.episodeId, original.episodeId);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.isFilm, false);
    });
  });
}
