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

    test('expires entries after TTL', () async {
      cache.put('short', 'value', ttlMinutes: 0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final value = cache.get<String>('short');
      expect(value, isNull);
    });
  });
}
