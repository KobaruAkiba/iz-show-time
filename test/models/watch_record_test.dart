import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/utils/duration_format.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';

void main() {
  group('formatDurationMinutes', () {
    test('formats minutes only', () {
      expect(formatDurationMinutes(45), '45m');
    });

    test('formats hours and zero minutes', () {
      expect(formatDurationMinutes(120), '2h 0m');
    });

    test('formats hours and minutes', () {
      expect(formatDurationMinutes(135), '2h 15m');
    });

    test('formats days without months or years', () {
      // 55 hours = 2d 7h 0m
      expect(formatDurationMinutes(55 * 60), '2d 7h 0m');
    });

    test('formats months without years', () {
      // 45 days = 1M 15d 0h 0m
      expect(formatDurationMinutes(45 * 24 * 60), '1M 15d 0h 0m');
    });

    test('formats years and lower units', () {
      // 1y 2M 3d 4h 5m
      final minutes =
          (1 * 12 * 30 * 24 * 60) + (2 * 30 * 24 * 60) + (3 * 24 * 60) + (4 * 60) + 5;
      expect(formatDurationMinutes(minutes), '1y 2M 3d 4h 5m');
    });

    test('handles zero', () {
      expect(formatDurationMinutes(0), '0m');
    });

    test('hours-only hint appears from one day', () {
      expect(isAtLeastOneDay(23 * 60 + 59), false);
      expect(isAtLeastOneDay(24 * 60), true);
      expect(formatHoursOnlyHint(55 * 60), "that's 55 hours");
      expect(formatHoursOnlyHint(24 * 60), "that's 24 hours");
      expect(formatHoursOnlyHint(60), "that's 1 hour");
    });
  });

  group('WatchRecord', () {
    test('uses film key for movies', () {
      final record = WatchRecord(
        mediaId: 550,
        isFilm: true,
        durationMinutes: 139,
        watchedAt: DateTime(2024, 1, 1),
      );

      expect(record.watchKey, 'film_550');
    });

    test('uses episode id for TV episodes', () {
      final record = WatchRecord(
        mediaId: 1399,
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
      expect(original.toJson().containsKey('media_title'), isFalse);
    });

    test('reads legacy payloads that still include media_title', () {
      final restored = WatchRecord.fromJson({
        'media_id': 550,
        'media_title': 'Fight Club',
        'is_film': true,
        'duration_minutes': 139,
        'watched_at': '2024-01-01T00:00:00.000',
      });

      expect(restored.mediaId, 550);
      expect(restored.isFilm, isTrue);
      expect(restored.durationMinutes, 139);
    });
  });
}
