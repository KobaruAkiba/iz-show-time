import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/background/background_task_kind.dart';
import '../../../core/background/last_background_check.dart';
import '../../../l10n/l10n.dart';

/// Shows when the OS last ran the background episode check, so users can
/// tell whether background checks happen on their device.
///
/// Read once each time the Settings tab is shown; no box is kept open.
class BackgroundCheckStatusTile extends StatefulWidget {
  const BackgroundCheckStatusTile({
    super.key,
    this.isActive = true,
    this.readLastCheck = LastBackgroundCheck.read,
  });

  final bool isActive;
  final Future<LastBackgroundCheck> Function() readLastCheck;

  @override
  State<BackgroundCheckStatusTile> createState() =>
      _BackgroundCheckStatusTileState();
}

class _BackgroundCheckStatusTileState extends State<BackgroundCheckStatusTile> {
  /// Null while reading.
  LastBackgroundCheck? _lastCheck;

  @override
  void initState() {
    super.initState();
    // Settings is built hidden at launch: read only once it is shown.
    if (widget.isActive) _load();
  }

  @override
  void didUpdateWidget(covariant BackgroundCheckStatusTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  Future<void> _load() async {
    final lastCheck = await widget.readLastCheck();
    if (!mounted) return;
    setState(() => _lastCheck = lastCheck);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lastCheck = _lastCheck;

    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(l10n.settingsLastBackgroundCheckTitle),
      subtitle: lastCheck == null ? null : Text(_describe(l10n, lastCheck)),
    );
  }

  String _describe(AppLocalizations l10n, LastBackgroundCheck lastCheck) {
    return switch (lastCheck) {
      LastBackgroundCheckNever() => l10n.settingsLastBackgroundCheckNever,
      LastBackgroundCheckUnavailable() =>
        l10n.settingsLastBackgroundCheckUnavailable,
      LastBackgroundCheckAt(:final checkedAt, :final taskKind) =>
        _describeRun(l10n, checkedAt, taskKind),
    };
  }

  String _describeRun(
    AppLocalizations l10n,
    DateTime checkedAt,
    BackgroundTaskKind? taskKind,
  ) {
    final date = DateFormat.yMMMd().add_jm().format(checkedAt.toLocal());
    return switch (taskKind) {
      null => date,
      BackgroundTaskKind.periodic => l10n.settingsLastBackgroundCheckWithKind(
          date,
          l10n.settingsBackgroundTaskPeriodic,
        ),
      BackgroundTaskKind.nightly => l10n.settingsLastBackgroundCheckWithKind(
          date,
          l10n.settingsBackgroundTaskNightly,
        ),
    };
  }
}
