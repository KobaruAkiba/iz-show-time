import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/network/network_feedback.dart';

void main() {
  group('NetworkFeedback.runSilent', () {
    test('is silent only inside the action, awaits included', () async {
      expect(NetworkFeedback.isSilent, isFalse);

      await NetworkFeedback.runSilent(() async {
        expect(NetworkFeedback.isSilent, isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(NetworkFeedback.isSilent, isTrue);
      });

      expect(NetworkFeedback.isSilent, isFalse);
    });

    test('does not silence callers outside a silent task in flight', () async {
      final release = Completer<void>();
      final silentTask = NetworkFeedback.runSilent(() => release.future);

      expect(NetworkFeedback.isSilent, isFalse);

      release.complete();
      await silentTask;
    });

    test('returns the action result and propagates errors', () async {
      expect(await NetworkFeedback.runSilent(() async => 7), 7);
      await expectLater(
        NetworkFeedback.runSilent<void>(() async => throw StateError('boom')),
        throwsStateError,
      );
    });
  });
}
