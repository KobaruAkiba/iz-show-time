import 'package:flutter/foundation.dart';

import '../../data/repositories/background_check_outbox.dart';
import 'background_task_kind.dart';

/// What Settings shows about the last native background check.
sealed class LastBackgroundCheck {
  const LastBackgroundCheck();

  /// One-shot read of the outbox, written only by background runs (unlike
  /// the last episode check time, also set by in-app refreshes).
  static Future<LastBackgroundCheck> read({
    Future<BackgroundCheckResult?> Function() readOutbox =
        BackgroundCheckOutbox.read,
  }) async {
    try {
      final result = await readOutbox();
      if (result == null) return const LastBackgroundCheckNever();
      return LastBackgroundCheckAt(
        checkedAt: result.checkedAt,
        taskKind: result.taskKind,
      );
    } catch (error, stackTrace) {
      // The background isolate may be writing the file right now.
      debugPrint('Last background check unavailable: $error\n$stackTrace');
      return const LastBackgroundCheckUnavailable();
    }
  }
}

/// No background run has saved a result yet.
final class LastBackgroundCheckNever extends LastBackgroundCheck {
  const LastBackgroundCheckNever();
}

final class LastBackgroundCheckAt extends LastBackgroundCheck {
  const LastBackgroundCheckAt({required this.checkedAt, this.taskKind});

  final DateTime checkedAt;

  /// Null when saved by a version that did not record it.
  final BackgroundTaskKind? taskKind;
}

/// The outbox could not be read; retried the next time Settings is shown.
final class LastBackgroundCheckUnavailable extends LastBackgroundCheck {
  const LastBackgroundCheckUnavailable();
}
