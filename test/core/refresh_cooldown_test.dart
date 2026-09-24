import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/utils/refresh_cooldown.dart';

void main() {
  group('RefreshCooldown', () {
    const cooldown = Duration(seconds: 2);
    late RefreshCooldown gate;
    late DateTime t0;

    setUp(() {
      gate = RefreshCooldown(duration: cooldown);
      t0 = DateTime(2026, 1, 1, 12);
    });

    test('first tryBegin is accepted', () {
      expect(gate.tryBegin(t0), isTrue);
    });

    test('second tryBegin within cooldown is rejected', () {
      expect(gate.tryBegin(t0), isTrue);
      gate.end();

      expect(gate.tryBegin(t0.add(const Duration(seconds: 1))), isFalse);
    });

    test('tryBegin after cooldown expires is accepted', () {
      expect(gate.tryBegin(t0), isTrue);
      gate.end();

      expect(gate.tryBegin(t0.add(const Duration(seconds: 2))), isTrue);
    });

    test('tryBegin while in-flight is rejected even after cooldown', () {
      expect(gate.tryBegin(t0), isTrue);

      expect(gate.tryBegin(t0.add(const Duration(seconds: 5))), isFalse);
    });

    test('tryBegin succeeds again after end and cooldown', () {
      expect(gate.tryBegin(t0), isTrue);
      gate.end();

      expect(gate.tryBegin(t0.add(const Duration(seconds: 2))), isTrue);
      gate.end();
    });
  });
}
