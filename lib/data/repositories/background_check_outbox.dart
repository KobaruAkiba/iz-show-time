import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/new_episode_alert.dart';

/// Alerts computed by the background episode check.
class BackgroundCheckResult {
  final List<NewEpisodeAlert> alerts;
  final DateTime checkedAt;

  const BackgroundCheckResult({required this.alerts, required this.checkedAt});
}

/// Hive box written only by the background isolate.
///
/// Hive 2 boxes cannot be shared between isolates, so the background check
/// never writes to the user-data boxes owned by the UI isolate. It leaves its
/// result here for the UI isolate to pick up with [read].
class BackgroundCheckOutbox {
  BackgroundCheckOutbox._(this._box);

  static const String boxName = 'episode_check_outbox';
  static const String _alertsKey = 'alerts';
  static const String _checkedAtKey = 'checked_at';
  static const String _notifiedEpisodeIdsKey = 'notified_episode_ids';
  static const String _resumeAfterShowIdKey = 'resume_after_show_id';

  final Box<dynamic> _box;

  /// Background isolate only.
  static Future<BackgroundCheckOutbox> openForWriting() async {
    return BackgroundCheckOutbox._(await Hive.openBox<dynamic>(boxName));
  }

  /// Episode ids already notified, or null when never stored here.
  Set<int>? get notifiedEpisodeIds {
    final raw = _box.get(_notifiedEpisodeIdsKey);
    if (raw is! String) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return {
      for (final value in decoded)
        if (value is num) value.toInt(),
    };
  }

  /// Result of the previous run, if any.
  BackgroundCheckResult? get result => _parseResult(_box);

  /// Last show checked by the previous run: the next one resumes after it,
  /// so an interrupted run does not always leave the same shows unchecked.
  int? get resumeAfterShowId {
    final raw = _box.get(_resumeAfterShowIdKey);
    return raw is int ? raw : null;
  }

  Future<void> save({
    required List<NewEpisodeAlert> alerts,
    required DateTime checkedAt,
    required Set<int> notifiedEpisodeIds,
    int? resumeAfterShowId,
  }) async {
    await _box.putAll({
      _alertsKey: jsonEncode(alerts.map((alert) => alert.toJson()).toList()),
      _checkedAtKey: checkedAt.toIso8601String(),
      _notifiedEpisodeIdsKey: jsonEncode(notifiedEpisodeIds.toList()..sort()),
      if (resumeAfterShowId != null) _resumeAfterShowIdKey: resumeAfterShowId,
    });
    await _box.flush();
  }

  Future<void> close() => _box.close();

  /// UI isolate: one-shot read, never keeps the box open.
  ///
  /// Throws when the file is being written by the background isolate; callers
  /// retry on the next resume.
  static Future<BackgroundCheckResult?> read() async {
    if (!await Hive.boxExists(boxName)) return null;
    // No crash recovery: it would truncate a file this isolate does not own.
    final box = await Hive.openBox<dynamic>(boxName, crashRecovery: false);
    try {
      return _parseResult(box);
    } finally {
      await box.close();
    }
  }

  static BackgroundCheckResult? _parseResult(Box<dynamic> box) {
    final rawAlerts = box.get(_alertsKey);
    final rawCheckedAt = box.get(_checkedAtKey);
    if (rawAlerts is! String || rawCheckedAt is! String) return null;
    final checkedAt = DateTime.tryParse(rawCheckedAt);
    final decoded = jsonDecode(rawAlerts);
    if (checkedAt == null || decoded is! List) return null;
    return BackgroundCheckResult(
      checkedAt: checkedAt,
      alerts: [
        for (final entry in decoded)
          if (entry is Map)
            NewEpisodeAlert.fromJson(Map<String, dynamic>.from(entry)),
      ],
    );
  }

  /// Drops the stored result (clear all data / backup restore).
  static Future<void> delete() async {
    if (!await Hive.boxExists(boxName)) return;
    await Hive.deleteBoxFromDisk(boxName);
  }
}
