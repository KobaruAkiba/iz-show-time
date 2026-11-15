import 'package:flutter/material.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../l10n/l10n.dart';

/// Settings entry for episode alerts.
///
/// The only way back for users who dismissed the first-launch rationale:
/// shows the current permission state and asks for it when off.
class NotificationsTile extends StatefulWidget {
  const NotificationsTile({super.key});

  @override
  State<NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<NotificationsTile> {
  final _notifications = NotificationService();

  /// Null while the permission state is being read.
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await _notifications.areNotificationsEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  Future<void> _onTap() async {
    if (_enabled ?? false) return;

    final granted = await _notifications.requestPermission();
    if (!mounted) return;
    setState(() => _enabled = granted);
    if (granted) return;

    // The OS no longer shows its prompt once the user has denied it.
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.notifications_off_outlined),
        title: Text(l10n.settingsNotificationsBlockedTitle),
        content: Text(l10n.settingsNotificationsBlockedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.actionDismiss),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = _enabled;

    return ListTile(
      leading: Icon(
        enabled ?? false
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
      ),
      title: Text(l10n.settingsNotificationsTitle),
      subtitle: enabled == null
          ? null
          : Text(
              enabled
                  ? l10n.settingsNotificationsOn
                  : l10n.settingsNotificationsOff,
            ),
      trailing: enabled == false ? const Icon(Icons.chevron_right) : null,
      onTap: enabled == false ? _onTap : null,
    );
  }
}
