import 'package:flutter/material.dart';

import '../../data/repositories/user_data_store.dart';
import '../../l10n/l10n.dart';

/// Shows a one-time in-app rationale before the OS notification permission
/// dialog. Returns `true` when the user chooses to continue to the system
/// prompt.
Future<bool> showNotificationPermissionPrePrompt({
  required UserDataStore userDataStore,
  required GlobalKey<NavigatorState> navigatorKey,
}) async {
  if (await userDataStore.loadNotificationPermissionPrePromptShown()) {
    return false;
  }

  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    // Retry on a later launch when the navigator is ready.
    return false;
  }

  final l10n = context.l10n;
  final proceed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.notifications_outlined),
      title: Text(l10n.notificationPermissionTitle),
      content: Text(l10n.notificationPermissionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.notificationPermissionNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.notificationPermissionContinue),
        ),
      ],
    ),
  );

  await userDataStore.saveNotificationPermissionPrePromptShown(true);
  await userDataStore.flush();
  return proceed ?? false;
}
