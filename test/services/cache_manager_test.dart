import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/cache/cache_manager.dart';

void main() {
  group('CacheManager', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager();
      cache.clearAll();
    });

    test('stores and retrieves values', () {
      cache.put('key', {'foo': 'bar'}, ttlMinutes: 60);
      final value = cache.get<Map<String, dynamic>>('key');
      expect(value?['foo'], 'bar');
    });

    test('returns the stored object without re-decoding it', () {
      final payload = {'foo': 'bar'};
      cache.put('key', payload, ttlMinutes: 60);

      expect(identical(cache.get<Map<String, dynamic>>('key'), payload), isTrue);
    });

    test('returns null when the stored shape does not match', () {
      cache.put('key', 'text', ttlMinutes: 60);

      expect(cache.get<Map<String, dynamic>>('key'), isNull);
    });

    test('evicts the least recently used entry beyond the cap', () {
      for (var index = 0; index < CacheManager.maxEntries; index++) {
        cache.put('key$index', index, ttlMinutes: 60);
      }
      // Reading key0 makes key1 the oldest entry.
      expect(cache.get<int>('key0'), 0);

      cache.put('extra', -1, ttlMinutes: 60);

      expect(cache.keys, hasLength(CacheManager.maxEntries));
      expect(cache.get<int>('key0'), 0);
      expect(cache.get<int>('key1'), isNull);
    });

    test('keys can be iterated while reading entries', () {
      cache.put('a', 1, ttlMinutes: 60);
      cache.put('b', 2, ttlMinutes: 60);

      expect([for (final key in cache.keys) cache.get<int>(key)], [1, 2]);
    });

    test('expires entries after TTL', () async {
      cache.put('short', 'value', ttlMinutes: 0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final value = cache.get<String>('short');
      expect(value, isNull);
    });
  });
}
